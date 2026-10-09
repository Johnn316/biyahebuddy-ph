package ph.biyahebuddy.biyahebuddy_ph.sos

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** MethodChannel "ph.biyahebuddy/sos" used by lib/data/sos/sos_platform.dart. */
class SosChannel(private val ctx: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, "ph.biyahebuddy/sos").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "canSendSms" -> result.success(SosTelephony.canSendSms(ctx))
                "canCall" -> result.success(SosTelephony.canCall(ctx))
                "sendSms" -> {
                    val numbers = call.argument<List<String>>("numbers") ?: emptyList()
                    val message = call.argument<String>("message") ?: ""
                    SosTelephony.sendSms(ctx, numbers, message) { failed -> result.success(failed) }
                }
                "enableVolumeTrigger" -> {
                    SosContacts.save(ctx, call.argument<String>("contacts") ?: "[]")
                    ctx.startForegroundService(
                        VolumeSosService.intent(ctx, VolumeSosService.ACTION_START),
                    )
                    result.success(null)
                }
                "disableVolumeTrigger" -> {
                    ctx.startService(VolumeSosService.intent(ctx, VolumeSosService.ACTION_STOP))
                    result.success(null)
                }
                "isVolumeTriggerOn" -> result.success(VolumeSosService.isRunning)
                "debugTrigger" -> {
                    ctx.startForegroundService(
                        VolumeSosService.intent(ctx, VolumeSosService.ACTION_TRIGGER),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("sos_error", e.message, null)
        }
    }
}
