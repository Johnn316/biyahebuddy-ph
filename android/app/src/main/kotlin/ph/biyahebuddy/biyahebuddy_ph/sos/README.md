# Native volume-button SOS — BACKEND (teammate)

Placeholder for the Kotlin side of `SosService.enableVolumeTrigger()`.

Planned pieces:
- `VolumeSosService.kt` — foreground service (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`
  / `FOREGROUND_SERVICE_LOCATION`) that keeps a silent `MediaSession` so volume
  key presses are received while the screen is off.
- Trigger pattern (e.g. volume-down pressed 3x within 2s) → fires SOS.
- `MethodChannel("ph.biyahebuddy/sos")` registered in `MainActivity.kt` to
  start/stop the service from Dart (`lib/data/sos/`).
- Declare the `<service>` with the right `android:foregroundServiceType` in
  `AndroidManifest.xml` (permissions are already declared).

Fully offline: SMS via `SmsManager`, location via GPS only.
