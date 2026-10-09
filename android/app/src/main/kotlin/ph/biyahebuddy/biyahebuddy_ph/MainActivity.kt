package ph.biyahebuddy.biyahebuddy_ph

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import ph.biyahebuddy.biyahebuddy_ph.sos.SosChannel
import ph.biyahebuddy.biyahebuddy_ph.sos.VolumeSosService

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SosChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    // While the app is open, the Activity gets volume keys before any
    // MediaSession, so forward volume-up presses to the SOS counter here.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP && VolumeSosService.isRunning) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                startService(VolumeSosService.intent(this, VolumeSosService.ACTION_PRESS))
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
