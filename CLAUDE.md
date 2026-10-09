# CLAUDE.md — BiyaheBuddy PH

## Project summary

BiyaheBuddy PH is an **offline** AI driving companion Android app for Filipino
drivers, built in Flutter for a hackathon. Features: emergency SOS (GPS + SMS +
dialer + volume-button trigger), fines lookup when flagged (LTO/MMDA/city),
on-device AI Q&A about traffic laws (RAG over local law chunks), number-coding
status, and a driver profile with QR card.

Package: `ph.biyahebuddy.biyahebuddy_ph` · minSdk 26 · state: Riverpod ·
routing: go_router · storage: sqlite3 + shared_preferences.

Pinned on purpose: `permission_handler: ^12.0.1`. The 13.x line pulls
`permission_handler_android` 14.x, and its Gradle script fails to compile with
this project's AGP 8.11 / Kotlin 2.2 setup. Don't bump it without running
`flutter build apk --debug`. Riverpod is on 2.6.x, the newest version this
SDK (Flutter 3.41) can resolve.

## Offline-first rule (non-negotiable)

- Every feature must work with **no network**. Never add a runtime network call.
- The only allowed network use is the **one-time on-device model download**.
- No analytics, no cloud APIs, no remote config.
- LLM model files are never committed (`*.gguf *.task *.tflite *.bin *.litertlm models/`
  are git-ignored).

## Folder ownership

| Path | Owner | Rule |
|---|---|---|
| `lib/core/` | **Shared** (John + backend) | Agree with each other before editing. Contracts change = both approve the PR. |
| `lib/features/` | **Frontend — John** | UI only. Import only from `lib/core/` — never from `lib/data/`. |
| `lib/data/`, `android/` native (incl. `kotlin/.../sos/`) | **Backend — teammate** | Implements `lib/core/contracts/contracts.dart`. |
| `assets/data/`, `docs/SOURCES.md` | **Devin** | Must match the JSON schemas below; every entry needs an official source. |

- **Frontend uses fakes until backend merges real implementations.** The switch
  is `useFakes` in `lib/core/di/providers.dart`; backend wires real impls there.
- Fakes live in `lib/core/fakes/` and must keep compiling against the contracts.

### Data schemas (`assets/data/`)

- `laws.json`: `[{id, source, section, title, text, tags}]`
- `fines.json`: `[{violation, agency: lto|mmda|city, amount, legal_basis, aliases}]`
- `hotlines.json`: `[{name, number, zone}]` (`zone: null` = nationwide)
- `coding.json`: `{scheme, hours, days: {"1": [digits], ...}, notes}` (ISO weekday keys)

Current files are **SAMPLE** data — not verified.

## Branch rules

- Branch names: `frontend/<feature>`, `backend/<feature>` (data: `data/<topic>`).
- Never push directly to `main`; open a PR into `main`.
- **Pull `main` into your branch every hour.**
- Before every PR: `flutter analyze` clean, `flutter test` passing,
  `flutter build apk --debug` succeeds.
- Commit style: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.

## AI answer-format rules (in-app assistant)

Every `AiAssistant` answer must be, in order:

1. **Kalma muna** — short, calming opener (driver may be stressed).
2. **Batas** — the relevant law **with citation** (source + section). Never
   invent a law; if no chunk matches, say so plainly.
3. **Pagsusuri** — analysis of the driver's situation.
4. **Gagawin** — numbered, concrete next steps.

Also: Filipino/Taglish by default, short sentences, no legal-advice claims,
cite only from `laws.json` / `fines.json` retrieved chunks, recommend 911 when
anyone is hurt. `analyzeTwoSides` stays neutral between Driver A and Driver B.

## UI rules

- High contrast, large text, min 64dp tap targets, one-thumb use.
- Red (`AppColors.emergency`) is reserved for emergency actions.
- Home screen fills the screen: status strip → big EMERGENCY → two equal buttons.

## Workflow rule

**Update the STATUS section below after each feature is merged.**

## STATUS

_Last updated: 2026-10-09_

| Area | Owner | State |
|---|---|---|
| Project scaffold | John | ✅ Done |
| Contracts + fakes | Shared | ✅ v1 (fakes only) |
| Home screen | John | 🟡 Basic layout on fakes — branch `frontend/home` |
| Onboarding / Emergency / Violation / Chat / Profile | John | ⬜ Placeholder screens |
| Local DB + JSON loaders | Backend | ⬜ Not started |
| CodingService (real) | Backend | ⬜ Not started |
| AI / RAG (LLM package TBD after spike) | Backend | ⬜ Not started |
| Native volume SOS | Backend | ⬜ Not started |
| Verified data + SOURCES.md | Devin | ⬜ SAMPLE data only |
