# Buddy eval harness

Measures how well Buddy finds the right law sections and fines, and how the
on-device LLM answers — on a PC, no phone needed. It runs the **same Dart
code as the app** (`AppDatabase`, `LawRetriever` / `HybridRetriever`,
`LocalAiAssistant`, `LocalLlm` via llama.cpp) on the same assets and GGUF
files.

## Question sets

| File | Use |
|---|---|
| `questions.json` | 30 Taglish / Tagalog / English questions with the expected law sections and/or fines. Used while improving retrieval. |
| `holdout.json` | 10 more questions written **before** any tuning and never used to tune. Shows whether gains generalize. Don't tune on it. |

Each entry: `{id, lang, intent, question, driverB?, laws?: [ids], fines?: [keywords]}`.
A question **passes** when at least one expected law id is among the cited
sections (`ra4136-s34` also matches `ra4136-s34-p2`) and at least one cited
fine's violation contains an expected keyword.

## Run

Model files go in `models/` (git-ignored). Same URLs as `lib/data/ai/model_catalog.dart`.

```bash
# keyword-only retrieval (the original behaviour)
dart run tools/eval/run_eval.dart --label fts

# hybrid retrieval (what the app ships)
dart run tools/eval/run_eval.dart --label hybrid --retriever hybrid \
    --embedder models/embeddinggemma-300M-Q8_0.gguf

# + real answers from the LLM (adds answer time and citation checks)
dart run tools/eval/run_eval.dart --label hybrid-1b --retriever hybrid \
    --llm models/gemma-3-1b-it-Q4_K_M.gguf

# held-out set
dart run tools/eval/run_eval.dart --label holdout --retriever hybrid --set tools/eval/holdout.json
```

Output: one block per question (cited sections, hit/miss, answer, time) and a
summary — retrieval accuracy, law/fine hit rates, answer time, how often the
analysis cites an expected section, and how often it cites a section that was
**not** retrieved (the citation guard should keep that at 0%). Results are
written to `results/<label>.json`.

Answer times are **PC CPU** times; a phone is several times slower.

## Rebuild embeddings after data changes

`assets/data/embeddings.json` must match `laws.json`, `fines.json` and
`faq.json`; the app falls back to keyword-only retrieval if it doesn't, and
`test/data/hybrid_retriever_test.dart` fails.

```bash
dart run tools/build_embeddings.dart --model models/embeddinggemma-300M-Q8_0.gguf
```

## Ask Buddy yourself (interactive, offline)

```bash
dart run tools/eval/ask.dart            # Gemma 3 1B + EmbeddingGemma from models/
dart run tools/eval/ask.dart --llm models/gemma-3-4b-it-Q4_K_M.gguf
```

Same pipeline as the app (`LocalAiAssistant` → intent routing, hybrid
retrieval + FAQ boost, same prompts, citation guard, 4-section answer).
For each question it prints the detected intent, the top law candidates and
fine types with their fused scores (first 3 non-boilerplate laws / first 2
fine types are cited), FAQ matches, then streams the answer exactly as the
app shows it, with retrieval / first-text / total times.

| Command | |
|---|---|
| *any text* | ask (Taglish / Tagalog / English) |
| `/two` | Dalawang panig: asks Driver A, then Driver B |
| `/bad <note>` | appends the last question, what was retrieved, the answer and your note to `tools/eval/feedback.json` — fix it, then add a similar question to `questions.json` (never `holdout.json`) |
| `/quit` | exit |

Fully offline: it only reads `assets/data/` and `models/`.
