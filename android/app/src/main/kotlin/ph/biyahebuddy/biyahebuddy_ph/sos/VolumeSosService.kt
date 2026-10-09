package ph.biyahebuddy.biyahebuddy_ph.sos

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import java.util.Locale

/**
 * Volume-button SOS. Foreground service that keeps a MediaSession (plus a
 * silent audio loop so the session gets volume keys with the screen off).
 *
 * Volume-up 5x within 3 s → 5 s vibrating countdown with Cancel → GPS fix
 * (LocationManager) → SMS all emergency contacts → call the first one.
 * Steps the device can't do (no SIM on a Wi-Fi tablet, permission denied)
 * are skipped and explained in the result notification. Fully offline.
 */
class VolumeSosService : Service() {
    companion object {
        private const val TAG = "BuddySos"
        const val ACTION_START = "ph.biyahebuddy.sos.START"
        const val ACTION_STOP = "ph.biyahebuddy.sos.STOP"
        const val ACTION_PRESS = "ph.biyahebuddy.sos.PRESS"
        const val ACTION_CANCEL = "ph.biyahebuddy.sos.CANCEL"
        const val ACTION_TRIGGER = "ph.biyahebuddy.sos.TRIGGER"

        private const val CH_ARMED = "sos_armed"
        private const val CH_ALERT = "sos_alert"
        private const val ID_ARMED = 4101
        private const val ID_ALERT = 4102

        private const val PRESSES = 5
        private const val WINDOW_MS = 3_000L
        private const val COUNTDOWN_S = 5

        @Volatile
        var isRunning = false
            private set

        fun intent(ctx: Context, action: String) =
            Intent(ctx, VolumeSosService::class.java).setAction(action)
    }

    private val handler = Handler(Looper.getMainLooper())
    private val presses = ArrayDeque<Long>()
    private var session: MediaSession? = null
    private var silence: AudioTrack? = null
    private var countingDown = false
    private var sending = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PRESS -> onVolumeUp()
            ACTION_CANCEL -> cancelCountdown()
            ACTION_TRIGGER -> {
                ensureForeground()
                startCountdown()
            }
            else -> ensureForeground() // ACTION_START, or restart after kill
        }
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        session?.release()
        session = null
        silence?.runCatching { stop(); release() }
        silence = null
        super.onDestroy()
    }

    // ---- foreground + volume keys -------------------------------------

    /** Every startForegroundService() must be answered with startForeground(). */
    private fun ensureForeground() {
        val notification = armedNotification()
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                var type = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                // Location type only with permission, else Android 14 throws.
                if (SosTelephony.granted(this, Manifest.permission.ACCESS_FINE_LOCATION) ||
                    SosTelephony.granted(this, Manifest.permission.ACCESS_COARSE_LOCATION)
                ) {
                    type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                }
                startForeground(ID_ARMED, notification, type)
            } else {
                startForeground(ID_ARMED, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            stopSelf()
            return
        }
        isRunning = true
        if (session == null) startMediaSession()
    }

    private fun startMediaSession() {
        val s = MediaSession(this, "BuddySos")
        s.setPlaybackToRemote(object : VolumeProvider(VOLUME_CONTROL_RELATIVE, 100, 50) {
            override fun onAdjustVolume(direction: Int) {
                if (direction > 0) handler.post { onVolumeUp() }
            }
        })
        s.setPlaybackState(
            PlaybackState.Builder()
                .setState(PlaybackState.STATE_PLAYING, 0, 1f)
                .build(),
        )
        s.isActive = true
        session = s
        startSilence()
    }

    /** A looping silent track: keeps this session the one that gets volume keys. */
    private fun startSilence() {
        try {
            val rate = 8000
            val frames = rate // 1 s
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_UNKNOWN)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(frames * 2)
                .build()
            track.write(ShortArray(frames), 0, frames)
            track.setLoopPoints(0, frames, -1)
            track.play()
            silence = track
        } catch (e: Exception) {
            Log.w(TAG, "silent track failed; volume keys may need the screen on", e)
        }
    }

    // ---- trigger + countdown ------------------------------------------

    private fun onVolumeUp() {
        if (countingDown || sending) return
        val now = System.currentTimeMillis()
        presses.addLast(now)
        while (presses.isNotEmpty() && now - presses.first() > WINDOW_MS) presses.removeFirst()
        if (presses.size >= PRESSES) {
            presses.clear()
            startCountdown()
        }
    }

    private fun startCountdown() {
        if (countingDown || sending) return
        countingDown = true
        tick(COUNTDOWN_S)
    }

    private fun tick(secondsLeft: Int) {
        if (!countingDown) return
        if (secondsLeft == 0) {
            countingDown = false
            runSos()
            return
        }
        vibrate(400)
        notifyAlert(
            "SOS sa $secondsLeft…",
            "Ipapadala ang lokasyon mo sa emergency contacts. Pindutin ang KANSELAHIN kung hindi emergency.",
            withCancel = true,
        )
        handler.postDelayed({ tick(secondsLeft - 1) }, 1_000L)
    }

    private fun cancelCountdown() {
        if (!countingDown) return
        countingDown = false
        handler.removeCallbacksAndMessages(null)
        notifyAlert("SOS kinansela", "Walang ipinadala.", withCancel = false)
    }

    // ---- the SOS itself -----------------------------------------------

    private fun runSos() {
        sending = true
        notifyAlert("SOS: kinukuha ang lokasyon…", "Sandali lang.", withCancel = false)
        SosLocation.current(this) { location ->
            val message = sosMessage(location)
            val contacts = SosContacts.load(this)
            val notes = mutableListOf<String>()
            if (location == null) notes.add("Walang GPS fix — ipinadala nang walang lokasyon.")

            fun finish(sentTo: Int) {
                if (contacts.isNotEmpty()) {
                    if (SosTelephony.placeCall(this, contacts.first())) {
                        notes.add("Tinatawagan si ${contacts.first()}.")
                    } else if (SosTelephony.canCall(this)) {
                        notes.add("Hindi makatawag (walang pahintulot sa tawag).")
                    } else {
                        notes.add("Walang SIM — hindi makatawag.")
                    }
                }
                val title = if (sentTo > 0) "SOS naipadala sa $sentTo contact" else "SOS: hindi naipadala ang text"
                notifyAlert(title, (listOf(message) + notes).joinToString("\n"), withCancel = false)
                sending = false
            }

            when {
                contacts.isEmpty() -> {
                    notes.add("Wala pang emergency contact sa Profile.")
                    finish(0)
                }
                !SosTelephony.canSendSms(this) -> {
                    notes.add("Walang SIM ang device na ito — hindi makapag-text o makatawag.")
                    finish(0)
                }
                !SosTelephony.granted(this, Manifest.permission.SEND_SMS) -> {
                    notes.add("Walang pahintulot sa SMS — payagan sa Settings.")
                    finish(0)
                }
                else -> SosTelephony.sendSms(this, contacts, message) { failed ->
                    if (failed.isNotEmpty()) notes.add("Hindi naipadala sa: ${failed.joinToString()}.")
                    finish(contacts.size - failed.size)
                }
            }
        }
    }

    private fun sosMessage(location: Location?): String {
        val where = if (location == null) {
            "hindi makuha ang GPS"
        } else {
            String.format(
                Locale.US,
                "https://maps.google.com/?q=%.6f,%.6f",
                location.latitude,
                location.longitude,
            )
        }
        return "SOS! Naaksidente ako. Lokasyon: $where"
    }

    // ---- notifications + vibration ------------------------------------

    private fun createChannels() {
        val nm = getSystemService(NotificationManager::class.java) ?: return
        nm.createNotificationChannel(
            NotificationChannel(CH_ARMED, "SOS (naka-on)", NotificationManager.IMPORTANCE_LOW),
        )
        nm.createNotificationChannel(
            NotificationChannel(CH_ALERT, "SOS alert", NotificationManager.IMPORTANCE_HIGH),
        )
    }

    private fun pending(action: String, code: Int): PendingIntent =
        PendingIntent.getService(
            this,
            code,
            intent(this, action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun builder(channel: String) =
        Notification.Builder(this, channel).setSmallIcon(applicationInfo.icon)

    private fun armedNotification(): Notification =
        builder(CH_ARMED)
            .setContentTitle("BiyaheBuddy SOS naka-on")
            .setContentText("Pindutin ang volume-up nang 5 beses para humingi ng tulong.")
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, "I-off", pending(ACTION_STOP, 1)).build())
            .build()

    private fun notifyAlert(title: String, text: String, withCancel: Boolean) {
        val b = builder(CH_ALERT)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setCategory(Notification.CATEGORY_ALARM)
            .setOnlyAlertOnce(false)
        if (withCancel) {
            b.addAction(Notification.Action.Builder(null, "KANSELAHIN", pending(ACTION_CANCEL, 2)).build())
        }
        try {
            getSystemService(NotificationManager::class.java)?.notify(ID_ALERT, b.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "notifications not allowed", e)
        }
    }

    private fun vibrate(ms: Long) {
        try {
            val v: Vibrator? = if (Build.VERSION.SDK_INT >= 31) {
                getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Vibrator::class.java)
            }
            v?.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
        } catch (_: Exception) {
        }
    }
}
