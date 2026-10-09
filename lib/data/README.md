# lib/data — BACKEND (teammate)

Real implementations of the interfaces in `lib/core/contracts/contracts.dart`.
Frontend never imports from here; wire implementations in `lib/core/di/providers.dart`.

| Folder | Implements |
|---|---|
| `local/` | sqlite3 DB setup, asset JSON loaders (assets/data/*.json) |
| `repositories/` | `ProfileRepository`, `FinesRepository`, `HotlineRepository` |
| `coding/` | `CodingService` (reads assets/data/coding.json) |
| `ai/` | `AiAssistant` (on-device LLM — package TBD after spike) |
| `rag/` | Retrieval over `LawChunk`s from assets/data/laws.json |
| `sos/` | `SosService` (Dart side; native volume trigger in android/.../sos/) |
