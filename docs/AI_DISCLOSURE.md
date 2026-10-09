# AI Disclosure

Every model, package, framework, API, asset and AI dev tool used in
BiyaheBuddy PH. Update this file whenever one is added or removed.

## Runs locally

Everything here works in airplane mode.

| Item | Type | Purpose |
|---|---|---|
| Gemma 3 1B IT, Q4_K_M GGUF (`ggml-org/gemma-3-1b-it-GGUF`, ~806 MB, Gemma Terms of Use) | Model | Traffic-law Q&A, two-sides analysis |
| llama.cpp via `llamadart` (MIT) | Package | Runs the GGUF LLM on the phone CPU |
| Whisper base, multilingual (`ggerganov/whisper.cpp` `ggml-base.bin`, ~148 MB, MIT) | Model | Local speech recognition, Filipino + English |
| whisper.cpp via `whisper_ggml` (MIT; bundles `ffmpeg_kit_flutter_new_min` for local audio conversion) | Package | Runs Whisper on the phone |
| `record` | Package | Records 16 kHz mono WAV from the mic for Whisper |
| Local RAG over `assets/data/laws.json` | Asset + code | Grounds answers in cited law sections |
| `assets/data/*.json` (laws, fines, hotlines, coding) | Asset | SAMPLE data; sources in [SOURCES.md](SOURCES.md) |
| Flutter / Dart | Framework | App UI and logic |
| flutter_riverpod, go_router | Package | State management, navigation |
| sqlite3 (bundles SQLite with FTS5), shared_preferences, path_provider | Package | Local storage, FTS5 search for RAG |
| geolocator | Package | GPS location for SOS (no network geocoding) |
| url_launcher | Package | Opens the phone dialer / SMS app |
| permission_handler | Package | Runtime permissions |
| qr_flutter | Package | Driver profile QR card |
| Android SmsManager, foreground service (Kotlin) | Platform API | SOS SMS, volume-button trigger |

## Requires internet

| Item | When | Purpose |
|---|---|---|
| Model download (`ModelManager.downloadModels()`) | Once, on first launch | Fetches `gemma-3-1b-it-Q4_K_M.gguf` and `ggml-base.bin` from huggingface.co (public, no account/token) into app storage. Resumable. |

No other feature uses the network. No cloud AI APIs are used.

Build time only (developer machine, not the app): `llamadart` and `sqlite3`
build hooks download prebuilt native libraries while compiling the APK.

## AI dev tools

Claude Code, Claude (chat), Devin.

| Tool | Used for |
|---|---|
| Claude Code | Project scaffold, code generation, refactoring, docs |
| Claude (chat) | Planning, design discussion, copywriting |
| Devin | Data collection/structuring for `assets/data/` |

All AI-generated legal content is checked against the official sources in
[SOURCES.md](SOURCES.md) before shipping.
