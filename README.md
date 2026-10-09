# BiyaheBuddy PH

An **offline** AI driving companion for Filipino drivers (Android, Flutter).

- **Emergency / SOS** — one tap (or volume-button trigger) shares your GPS
  location to emergency contacts by SMS and dials hotlines. No internet needed.
- **Na-flag ako** — look up LTO / MMDA / city fines and the legal basis when
  you get flagged down, with calm step-by-step guidance.
- **Tanong kay Buddy** — ask an on-device AI about traffic laws (voice or text).
  Answers follow: *Kalma muna → Batas (with citation) → Pagsusuri → Gagawin*.
- **Number coding** status for your plate, always visible on the home screen.
- **Profile** — license, plate, blood type, insurance, emergency contacts, QR card.

Everything runs on-device. Internet is only used once, to download the AI model.

## Run

Requirements: Flutter 3.41+ (Dart 3.11+), Android SDK, a device/emulator on
Android 8.0+ (API 26).

```bash
flutter pub get
flutter run            # debug on a connected device/emulator
flutter analyze        # must be clean before every PR
flutter test
flutter build apk --debug
```

The app runs entirely on **fakes** by default (`useFakes = true` in
`lib/core/di/providers.dart`).

## Team

| Who | Role | Owns |
|---|---|---|
| John | Frontend | `lib/features/` (UI, screens, widgets, controllers) |
| Backend teammate | Backend (on-device logic) | `lib/data/`, `android/` native code (SOS service) |
| Devin | Data | `assets/data/*.json`, `docs/SOURCES.md` |
| Both John + backend | Shared | `lib/core/` — agree before editing |

## Folder structure

```
lib/
  main.dart / app.dart     entry point, MaterialApp.router
  core/                    SHARED — contracts, theme, router, DI, fakes
  features/                FRONTEND — UI only, depends only on core/
  data/                    BACKEND — implements core/contracts
assets/data/               SAMPLE JSON data (laws, fines, hotlines, coding)
android/.../sos/           native volume-button SOS (backend)
docs/                      SOURCES.md, AI_DISCLOSURE.md
```

## Git workflow

- Branches: `frontend/<feature>`, `backend/<feature>`, `data/<topic>`.
- Open PRs into `main`. Pull `main` into your branch at least hourly.
- **Never commit model files** (`*.gguf`, `*.task`, `*.tflite`, `*.bin`,
  `*.litertlm`, `models/`) — they are git-ignored; GitHub rejects files >100 MB.

See [CLAUDE.md](CLAUDE.md) for the full working rules and current status.
