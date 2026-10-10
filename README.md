<p align="center">
  <img src="assets/icon/biyahebuddy_logo.png" alt="BiyaheBuddy PH logo" width="160">
</p>

# BiyaheBuddy PH

**An offline AI driving companion for Filipino drivers.** When you're flagged
down by an enforcer, in a fender-bender, or just unsure of a traffic rule,
BiyaheBuddy answers in Taglish with the actual law and fine — cited from
official Philippine sources — and helps you call for help, all without
internet. A small AI model runs on the phone itself: it reads your question,
finds the matching law sections and fines in a database bundled with the app,
and explains them calmly in four parts: *Kalma muna → Ano ang sinasabi ng
batas → Pagsusuri → Ano ang gagawin*. The law and the citations come from the
data, never from the AI's imagination.

Android (Flutter) · on-device AI · works in airplane mode after a one-time
model download.

## Team

| Member | Role |
|---|---|
| John Mark | Frontend / UI (Flutter screens, design, chat, violation and emergency flows) |
| Geno | Backend / on-device AI (retrieval, LLM, local database, SOS native service) |

AI tools used in development are listed in
[docs/AI_DISCLOSURE.md](docs/AI_DISCLOSURE.md).

## Features

- **Tanong kay Buddy (AI Buddy with law citations)** — ask anything about
  traffic rules in Taglish, Tagalog or English. The on-device AI finds the
  relevant sections of Philippine law and the matching fines, shows them word
  for word with their citation (e.g. *RA 10054 Sec. 7*), then explains and
  gives concrete next steps. If nothing in the data matches, it says so instead
  of guessing, and a guard stops the AI from citing a law section that
  wasn't retrieved. Tap a topic to see common questions; the most common ones
  get a curated, hand-written answer (checked against the law text).
- **Na-flag ako + IPAKITA** — pick the agency (LTO, MMDA, city) and the
  violation to see the official fine and its legal basis; **IPAKITA** shows a
  large, respectful message you can show the enforcer.
- **SOS with GPS SMS** — text one or all of your emergency contacts your
  GPS location, and one-tap call a contact, 911 or a hotline (opens the
  dialer). Works without data; uses Android's own location service, so it
  also works on phones without Google Play Services. On devices without a SIM
  it explains what it can't do instead of failing.
- **MMDA number coding** — your plate's coding status for today, always on
  the home screen.
- **Driver profile** — license, plate, blood type, insurance and emergency
  contacts, with a QR card.

## Install and first run

1. Install the APK on an Android 8.0+ phone (arm64; most phones since 2017):
   `app-arm64-v8a-release.apk`. Allow "install unknown apps" when asked.
2. Open the app and **download the AI models once on Wi-Fi: ~1.14 GB**
   (Gemma 3 1B 806 MB + EmbeddingGemma 300M 334 MB). The download resumes if
   interrupted.
3. Fill in your profile and emergency contacts.
4. From then on, **everything works fully offline** — turn on airplane mode
   and Buddy, Na-flag ako, SOS and coding all still work.

Build it yourself (Flutter 3.41+, Android SDK):

```bash
flutter pub get
flutter build apk --release --split-per-abi   # → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Why local AI

- **Works where drivers get stuck:** expressways, provincial roads, tunnels
  and checkpoints often have weak or no signal. An answer that needs the cloud
  fails exactly when it's needed.
- **No load needed:** after the one-time download, using Buddy costs nothing —
  no mobile data, no subscription.
- **Privacy:** location, license number, plate and accident details never
  leave the phone. No account, no analytics, no cloud AI.
- **Grounded, not guessed:** retrieval is local and deterministic, so every
  law and fine shown comes from the bundled official texts. The model only
  explains them, and a citation guard stops it from naming a law section
  that isn't on screen.

## Data scope

- **6 laws (161 sections):** RA 4136 (Land Transportation and Traffic Code),
  RA 10913 (Anti-Distracted Driving), RA 10586 (Anti-Drunk and Drugged
  Driving), RA 10054 (Motorcycle Helmet), RA 8750 (Seat Belts),
  RA 11229 (Child Safety in Motor Vehicles).
- **73 fines:** LTO (17), MMDA (32), Quezon City (24), each with its legal
  basis.
- Emergency hotlines and MMDA number-coding rules.
- Every source, URL and retrieval date: [docs/SOURCES.md](docs/SOURCES.md).

BiyaheBuddy gives guidance based on these texts; it is not legal advice.

## Roadmap

- **LTO Driver's Manual** — road markings, signs and driving basics (the
  official site blocked automated download during the hackathon).
- **More LGU ordinances** — fines and rules beyond Metro Manila and Quezon
  City.
- **Voice input** — on-device Whisper speech recognition is already in the
  code, disabled in this build pending phone testing.
- **Dalawang panig and volume-button SOS** — two-driver accident analysis and
  a volume-up ×5 SOS trigger are in the code, disabled in this build until
  they're tested on more phones.
- **Data-pack updates** — download updated laws and fines as a small data
  pack when online, without updating the app.

## For developers

| Path | What |
|---|---|
| `lib/features/` | UI (screens, widgets, controllers) |
| `lib/core/` | Shared contracts, theme, router, dependency injection, fakes |
| `lib/data/` | On-device backends: local DB, retrieval, LLM, SOS |
| `android/.../sos/` | Native SOS (SMS, location, volume-button trigger) |
| `assets/data/` | Laws, fines, hotlines, coding, precomputed embeddings |
| `tools/` | Data pipeline (`build_data.py`), embeddings, eval harness (`tools/eval/`) |

```bash
flutter analyze && flutter test
python3 tools/build_data.py --download   # rebuild laws.json from official texts
dart run tools/build_embeddings.dart     # after any change to laws/fines/faq
dart run tools/eval/run_eval.dart --retriever hybrid   # retrieval accuracy on the PC
```

Model files are never committed (`models/`, `*.gguf`, `*.bin` are
git-ignored). Working rules: [CLAUDE.md](CLAUDE.md).
