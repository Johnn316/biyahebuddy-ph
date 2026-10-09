# Native SOS — BACKEND

Kotlin side of `SosService` (Dart: `lib/data/sos/`). Fully offline. No Google
Play Services anywhere, so it works on Huawei devices.

| File | What |
|---|---|
| `SosChannel.kt` | `MethodChannel("ph.biyahebuddy/sos")`, registered in `MainActivity.kt` |
| `SosTelephony.kt` | SIM/SMS/call checks (`FEATURE_TELEPHONY_*` + `SIM_STATE_READY`), `SmsManager` with per-number sent results, `TelecomManager.placeCall` |
| `SosLocation.kt` | `android.location.LocationManager` (GPS + network), 15 s timeout, then newest last-known fix, then null |
| `SosContacts.kt` | Emergency numbers from the saved Profile (`flutter.profile_v1`), fallback to the list passed on enable |
| `VolumeSosService.kt` | Foreground service (`mediaPlayback`, + `location` when permitted) with a MediaSession and silent audio loop for volume keys |

Flow: volume-up ×5 within 3 s → 5 s vibrating countdown (notification with
KANSELAHIN) → GPS fix → SMS to all contacts → call the first contact. With
no SIM (Wi-Fi tablet) or a denied permission, those steps are skipped and the
result notification says why; nothing crashes. While the app is open,
`MainActivity.dispatchKeyEvent` forwards volume-up presses to the service.

Debug without pressing buttons: `flutter run -t lib/data/debug/debug_sos_main.dart`
→ "Debug trigger".

Huawei/EMUI kills background services. For the demo: Settings → Battery →
App launch → BiyaheBuddy PH → turn off "Manage automatically" and allow
auto-launch, secondary launch and run in background. Also allow
notifications for the app.
