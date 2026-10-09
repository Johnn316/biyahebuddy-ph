# BiyaheBuddy PH — Submission

## Project name

BiyaheBuddy PH

## Short description

An offline AI driving companion for Filipino drivers. Ask about any traffic
rule in Taglish, Tagalog or English and get the actual Philippine law and
fine — quoted word for word with its citation — plus a calm explanation and
next steps, from an AI that runs entirely on the phone. It also looks up the
correct LTO / MMDA / city fine when you're flagged down (with a respectful
message to show the enforcer), texts your GPS location to emergency contacts
and dials 911 or a hotline in one tap, and shows your MMDA number-coding
status. After a one-time
model download, everything works in airplane mode.

## Team members

| Member | Role |
|---|---|
| John Mark | Frontend / UI |
| Geno | Backend / on-device AI |

## GitHub

https://github.com/Johnn316/biyahebuddy-ph

## What runs locally

Everything the driver uses, in airplane mode:

- **Gemma 3 1B** (instruction-tuned, Q4_K_M, ~806 MB) via llama.cpp — writes
  the short explanation ("Pagsusuri") of each answer.
- **EmbeddingGemma 300M** (Q8_0, ~334 MB) via llama.cpp — understands the
  meaning of the driver's question (Taglish included) for retrieval.
- **Local retrieval (RAG)** — SQLite full-text search + the embedding vectors
  over the bundled law and fine database, fused and ranked on the phone.
- **Curated answers** — 34 hand-written answers to the most common questions
  (checked against the law text), shown when a question closely matches; plus
  tap-to-ask topic categories.
- **Bundled data** — 6 Philippine traffic laws (161 sections), 73 LTO / MMDA /
  Quezon City fines, emergency hotlines, MMDA number-coding rules.
- **SOS** — GPS (Android LocationManager), SMS and dialer, all without
  internet.
- In the code but disabled in this build: Whisper voice input, Dalawang
  panig (two-driver analysis) and the volume-button SOS trigger.

## What requires internet

Only the **one-time model download on first launch: ~1.14 GB** (Gemma 3 1B +
EmbeddingGemma 300M) from huggingface.co — public files, no account. Nothing
else: no cloud AI API, no analytics, no remote config, no login.

## Why does this product benefit from running AI locally?

- **It works where drivers actually need it.** Checkpoints, expressways,
  provincial roads and tunnels often have weak or no signal. A cloud chatbot
  fails exactly at the roadside moment a driver needs to know the rule or the
  fine. BiyaheBuddy answers with no connection at all.
- **No load needed.** After the one-time download, every question is free —
  no mobile data, no subscription — which matters for drivers on prepaid load.
- **Privacy.** Questions about an accident, a violation, your location,
  license number or plate never leave the phone. There is no account and no
  server that could log them.
- **It never invents laws.** The local retrieval step finds the matching law
  sections and fines in a bundled database built from official sources, and
  the app shows that text word for word with its citation. The small on-device
  model only explains what was retrieved, and a citation guard stops it from
  naming a section that wasn't retrieved. When nothing matches, Buddy says so
  instead of guessing. Running locally keeps that pipeline deterministic and
  auditable — the same question gives the same cited law, with or without
  signal.

## Links

- AI models, packages and tools used: [AI_DISCLOSURE.md](AI_DISCLOSURE.md)
- Data sources: [SOURCES.md](SOURCES.md)
