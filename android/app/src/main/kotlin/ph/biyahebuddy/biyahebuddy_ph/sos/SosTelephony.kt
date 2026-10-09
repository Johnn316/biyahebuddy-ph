package ph.biyahebuddy.biyahebuddy_ph.sos

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.TelecomManager
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.util.Log

/**
 * SIM / SMS / call capability checks and sending. Never throws: a Wi-Fi-only
 * tablet (no SIM) simply reports false / failed numbers.
 */
object SosTelephony {
    private const val TAG = "BuddySos"
    private const val ACTION_SENT = "ph.biyahebuddy.SOS_SMS_SENT"
    private const val SEND_TIMEOUT_MS = 30_000L

    private fun simReady(ctx: Context): Boolean {
        val tm = ctx.getSystemService(TelephonyManager::class.java) ?: return false
        return try {
            tm.simState == TelephonyManager.SIM_STATE_READY
        } catch (e: Exception) {
            false
        }
    }

    private fun hasFeature(ctx: Context, api33Feature: String): Boolean {
        val pm = ctx.packageManager
        return if (Build.VERSION.SDK_INT >= 33) {
            pm.hasSystemFeature(api33Feature)
        } else {
            pm.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        }
    }

    fun canSendSms(ctx: Context): Boolean =
        hasFeature(ctx, PackageManager.FEATURE_TELEPHONY_MESSAGING) && simReady(ctx)

    fun canCall(ctx: Context): Boolean =
        hasFeature(ctx, PackageManager.FEATURE_TELEPHONY_CALLING) && simReady(ctx)

    fun granted(ctx: Context, permission: String): Boolean =
        ctx.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /**
     * Sends [message] to every number. [done] gets the numbers that failed
     * (radio error, no service, or no result within 30 s). Main thread.
     */
    fun sendSms(
        ctx: Context,
        numbers: List<String>,
        message: String,
        done: (failed: List<String>) -> Unit,
    ) {
        if (numbers.isEmpty()) return done(emptyList())
        if (!canSendSms(ctx) || !granted(ctx, Manifest.permission.SEND_SMS)) {
            return done(numbers)
        }
        val app = ctx.applicationContext
        val sms: SmsManager = if (Build.VERSION.SDK_INT >= 31) {
            app.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }

        val pending = numbers.associateWith { 0 }.toMutableMap() // parts left
        val failed = linkedSetOf<String>()
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        lateinit var receiver: BroadcastReceiver

        fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacksAndMessages(null)
            try {
                app.unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
            failed.addAll(pending.filterValues { it > 0 }.keys) // timed out
            done(failed.toList())
        }

        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                val number = intent.getStringExtra("number") ?: return
                if (resultCode != Activity.RESULT_OK) failed.add(number)
                pending[number] = (pending[number] ?: 1) - 1
                if (pending.values.all { it <= 0 }) finish()
            }
        }
        val filter = IntentFilter(ACTION_SENT)
        if (Build.VERSION.SDK_INT >= 33) {
            app.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            app.registerReceiver(receiver, filter)
        }

        var requestCode = 0
        for (number in numbers) {
            try {
                val parts = sms.divideMessage(message)
                val intents = ArrayList<PendingIntent>()
                for (i in parts.indices) {
                    val intent = Intent(ACTION_SENT)
                        .setPackage(app.packageName)
                        .putExtra("number", number)
                    intents.add(
                        PendingIntent.getBroadcast(
                            app,
                            requestCode++,
                            intent,
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                        ),
                    )
                }
                pending[number] = parts.size
                sms.sendMultipartTextMessage(number, null, parts, intents, null)
            } catch (e: Exception) {
                Log.w(TAG, "SMS to $number failed", e)
                failed.add(number)
                pending[number] = 0
            }
        }
        if (pending.values.all { it <= 0 }) finish()
        handler.postDelayed({ finish() }, SEND_TIMEOUT_MS)
    }

    /** Places a call from the background (CALL_PHONE). Returns false if it can't. */
    fun placeCall(ctx: Context, number: String): Boolean {
        if (!canCall(ctx) || !granted(ctx, Manifest.permission.CALL_PHONE)) return false
        return try {
            val telecom = ctx.getSystemService(TelecomManager::class.java) ?: return false
            telecom.placeCall(Uri.fromParts("tel", number, null), Bundle())
            true
        } catch (e: Exception) {
            Log.w(TAG, "Call to $number failed", e)
            false
        }
    }
}
