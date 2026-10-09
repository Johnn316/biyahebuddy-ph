# AI Disclosure

Every model, package, framework, API, asset and AI dev tool used in
BiyaheBuddy PH. Update this file whenever one is added or removed.

## Runs locally

Everything here works in airplane mode.

### AI models (downloaded once, then on-device)

| Model | Size | License | Purpose |
|---|---|---|---|
| Gemma 3 1B IT, Q4_K_M GGUF (`ggml-org/gemma-3-1b-it-GGUF`) | ~806 MB | Gemma Terms of Use | Writes the short "Pagsusuri" (analysis) part of Buddy's answers |
| Whisper base, multilingual (`ggerganov/whisper.cpp`, `ggml-base.bin`) | ~148 MB | MIT | Speech-to-text, Filipino/Taglish + English. **Included in code, disabled in this build** (`kVoiceInputEnabled = false`): not downloaded, no mic buttons |
| EmbeddingGemma 300M, Q8_0 GGUF (`ggml-org/embeddinggemma-300M-GGUF`) | ~334 MB | Gemma Terms of Use | Embeds the driver's question for semantic (meaning-based) retrieval of law sections and fines; runs via llama.cpp |

The law text and citations in every answer are copied from `laws.json` /
`fines.json` by code (local RAG); the LLM never writes the law section.

### Packages, frameworks, platform APIs

| Item | Type | Purpose |
|---|---|---|
| Flutter / Dart | Framework | App UI and logic |
| llama.cpp via `llamadart` (MIT) | Package | Runs the GGUF LLM on the phone CPU |
| whisper.cpp via `whisper_ggml` (MIT; bundles `ffmpeg_kit_flutter_new_min`, LGPL, for local audio conversion) | Package | Runs Whisper on the phone (included in code, disabled in this build) |
| `record` | Package | Records 16 kHz mono WAV from the mic for Whisper (included in code, disabled in this build) |
| Local hybrid RAG over `assets/data/laws.json` + `fines.json` (+ `faq.json` when present): sqlite FTS5/bm25 keywords with light Tagalog root matching, EmbeddingGemma vectors, reciprocal rank fusion, rule-based intent routing | Code | Picks the law sections and fines that answers cite |
| Curated answers (`assets/data/faq.json`, 34 hand-written entries checked against `laws.json`): when a question is very close to one (EmbeddingGemma similarity ≥ 0.80, or word overlap ≥ 0.6 without the embedder), Buddy shows its hand-written Pagsusuri + 3 steps instead of generating them; the law section still comes from retrieval | Data + code | Correct, consistent answers to the most common questions, without the 1B model |
| Two-driver analysis ("Dalawang panig", `analyzeTwoSides`) | Code | Two-driver analysis: in code, disabled in this build (`kTwoSidesEnabled = false`) |
| `sqlite3` (bundles SQLite with FTS5), `shared_preferences`, `path_provider` | Package | Local storage, full-text search |
| `flutter_riverpod`, `go_router` | Package | State management, navigation |
| `geolocator` (forced onto Android LocationManager) | Package | GPS for SOS; no network geocoding. Its Android plugin includes Google's `play-services-location` library, which the app never calls, so it works without Google Play Services |
| `url_launcher` | Package | Opens the phone dialer |
| `permission_handler` | Package | Runtime permissions |
| `qr_flutter` | Package | Driver profile QR card |
| `cupertino_icons`, Material Icons | Font asset | Icons (bundled) |
| Plus Jakarta Sans (`assets/fonts/`, SIL OFL 1.1) | Font asset | App typography; bundled, never fetched at runtime |
| App logo (`assets/icon/`: `biyahebuddy_logo.png`, `app_icon.png`, `app_icon_background.png`, `app_icon_foreground.png`) | Image asset | App logo: generated with ChatGPT image generation (OpenAI), edited for app icon sizes. Bundled; launcher icons generated from it with `flutter_launcher_icons` (dev-only, build time) |
| Android SmsManager, TelecomManager, LocationManager, MediaSession foreground service (Kotlin) | Platform API | SOS SMS/call, GPS fix, volume-button trigger (all offline; skipped with a message on devices without a SIM) |

### Data (bundled assets, sources in [SOURCES.md](SOURCES.md))

| Asset | Content |
|---|---|
| `assets/data/laws.json` | Law sections from official texts (RA 4136, 10913, 10586, 10054, 8750, 11229), each with `url` and `as_of` |
| `assets/data/fines.json` | Fines for LTO, MMDA and Quezon City, with per-row legal basis |
| `assets/data/hotlines.json`, `assets/data/coding.json` | Emergency hotlines and MMDA number coding, with official sources |
| `assets/data/embeddings.json` | Precomputed EmbeddingGemma vectors for every law section and fine (and FAQ phrasing), built on a PC by `tools/build_embeddings.dart`; only the question is embedded on the phone |

## Requires internet

| Item | When | Purpose |
|---|---|---|
| Model download (`ModelManager.downloadModels()`) | Once, on first launch | Fetches `gemma-3-1b-it-Q4_K_M.gguf` and `embeddinggemma-300M-Q8_0.gguf` (~1.14 GB total; `ggml-base.bin` only when voice input is enabled) from huggingface.co (public, no account/token) into app storage. Resumable. |
| `tools/build_data.py --download` (dev only, not in the app) | When rebuilding data | Fetches law texts from lawphil.net; uses pdfplumber, BeautifulSoup, lxml, requests |

No other feature uses the network. No cloud AI APIs, analytics or remote
config are used.

Build time only (developer machine, not the app): `llamadart` and `sqlite3`
build hooks download prebuilt native libraries while compiling the APK.
Dev-only packages: `flutter_test`, `flutter_lints`.

Dev-only evaluation (`tools/eval/`, not in the app): runs the app's own
retrieval + answer code on a PC with the same GGUF files. Also downloaded for
comparison only: Gemma 3 4B IT Q4_K_M (`ggml-org/gemma-3-4b-it-GGUF`, Gemma
Terms of Use) and multilingual-e5-small Q8_0 (`keisuke-miyako/multilingual-e5-small-gguf-q8_0`,
MIT) — neither ships in the app.

## AI dev tools

| Tool | Used for |
|---|---|
| Claude Code | Project scaffold, backend and frontend code, refactoring, tests, docs |
| Claude (chat) | Planning, design discussion, prompts, copywriting |
| ChatGPT image generation (OpenAI) | App logo artwork |
| Devin | Legal data pipeline (`tools/build_data.py`) and data collection/structuring for `assets/data/` |

All AI-generated legal content is checked against the official sources in
[SOURCES.md](SOURCES.md) before shipping.
