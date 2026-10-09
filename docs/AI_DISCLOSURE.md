# AI Disclosure

Every model, package, framework, API, asset and AI dev tool used in
BiyaheBuddy PH. Update this file whenever one is added or removed.

## Runs locally

Everything here works in airplane mode.

| Item | Type | Purpose |
|---|---|---|
| On-device LLM (TBD after spike) | Model | Traffic-law Q&A, two-sides analysis |
| Whisper (variant TBD) | Model | Local speech recognition, Filipino + English |
| Local RAG over `assets/data/laws.json` | Asset + code | Grounds answers in cited law sections |
| `assets/data/*.json` (laws, fines, hotlines, coding) | Asset | SAMPLE data; sources in [SOURCES.md](SOURCES.md) |
| Flutter / Dart | Framework | App UI and logic |
| flutter_riverpod, go_router | Package | State management, navigation |
| sqlite3, sqlite3_flutter_libs, shared_preferences, path_provider | Package | Local storage |
| geolocator | Package | GPS location for SOS (no network geocoding) |
| url_launcher | Package | Opens the phone dialer / SMS app |
| permission_handler | Package | Runtime permissions |
| qr_flutter | Package | Driver profile QR card |
| Plus Jakarta Sans (`assets/fonts/`, SIL OFL 1.1) | Font asset | App typography; bundled, never fetched at runtime |
| Android SmsManager, foreground service (Kotlin) | Platform API | SOS SMS, volume-button trigger |

## Requires internet

| Item | When | Purpose |
|---|---|---|
| Model download (`ModelManager.downloadModels()`) | Once, on first launch | Fetches the LLM + Whisper model files (source URL TBD) |

No other feature uses the network. No cloud AI APIs are used.

## AI dev tools

Claude Code, Claude (chat), Devin.

| Tool | Used for |
|---|---|
| Claude Code | Project scaffold, code generation, refactoring, docs |
| Claude (chat) | Planning, design discussion, copywriting |
| Devin | Data collection/structuring for `assets/data/` |

All AI-generated legal content is checked against the official sources in
[SOURCES.md](SOURCES.md) before shipping.
