# AI tuning handoff — Buddy retrieval & answers

For: whoever continues tuning Buddy's answers (backend). Branch:
`feature/hybrid-retrieval` (PR into `main`, not merged yet).

## 1. Current state

### What's done on `feature/hybrid-retrieval`

| Commit | What |
|---|---|
| `feat(eval)` | PC eval harness `tools/eval/` — runs the app's own retrieval + `LocalAiAssistant` + llama.cpp on the PC. 30-question set + 10-question held-out set. |
| `feat(rag)` | Hybrid retrieval (FTS5 + EmbeddingGemma vectors, RRF), intent routing, FAQ boost (ready for `faq.json`), Tagalog root matching, fine ranking by violation type, citation guard, prompt fix, `assets/data/embeddings.json`, embedder in `ModelManager`. |
| `docs` | This file, `AI_DISCLOSURE.md`, `CLAUDE.md` status. |

### Accuracy

"Accuracy" = share of questions where every expectation is met: at least
one expected law section is among the cited sections, and at least one cited
fine matches the expected violation. Retrieval only — the LLM doesn't choose
what's cited.

| Step | Main set (30) | Held-out (10) |
|---|---|---|
| Baseline: FTS5 keyword-only | 56.7% (17/30) | 40% (4/10) |
| Keyword + Tagalog roots (query side only) | 63.3% | — |
| Hybrid v1: + EmbeddingGemma 300M, RRF | 73.3% | — |
| (same with multilingual-e5-small instead) | 40.0% ✗ worse than baseline | — |
| v2: clean fine docs, no penalty-section leak, fines for enforcer questions, fine→law links, anchors | 76.7% | — |
| v3: + roots in query, fines ranked by violation type | 83.3% | 80% (8/10) |
| **v4 (current): + roots on index side, everyday vocab** | **86.7% (26/30)** | **80% (8/10)** |

Law hit rate 85.7% (24/28), fine hit rate 91.7% (11/12) on the main set.
Retrieval adds ~40 ms per question on a PC (embedding the question).

### Answers: Gemma 3 1B vs 4B (Q4_K_M), same hybrid retrieval

PC CPU times (phone will be several times slower). "Invents a citation" = the
analysis names an RA section that wasn't retrieved, measured on the text the
user sees (after the citation guard).

| | Gemma 3 1B | Gemma 3 4B |
|---|---|---|
| Download | 806 MB | 2.49 GB |
| Retrieval accuracy | 86.7% | 86.7% (same retrieval) |
| Answer time, median (PC) | 5.0 s | 13.9 s (2.8× slower) |
| Answer time, max (PC) | 8.1 s | 24.4 s |
| Analysis cites an expected section | 3.6% (1/28) | **42.9% (12/28)** |
| Invents a citation — before guard (1B only) | 13.3% (4/30) | — |
| Invents a citation — after guard | 0% | 0%¹ |

**Recommendation:** **Ship Gemma 3 1B as the default.** Keep the 4B as an option to evaluate on
a real flagship phone later.

Why:
- **What the driver relies on is identical.** The law and fine citations in
  "Ano ang sinasabi ng batas" are written by code from retrieval, and retrieval
  is the same for both models (86.7%). The model only writes the short
  "Pagsusuri".
- **The 4B writes clearly better analyses** — it cites the right section in
  43% of answers vs 4% for the 1B, and reads more on-point.
- **But it's 2.8× slower on a PC CPU** (median 13.9 s vs 5.0 s, worst 24 s).
  On a mid-range phone that likely means 40 s+ per answer — too slow for a
  stressed driver at the roadside. Not measured on a phone yet.
- **3× the download (2.49 GB vs 0.8 GB) and RAM.** With the embedder and
  Whisper also loaded, the 4B needs roughly 3.5 GB+ free RAM; many Android
  phones would kill the app.

Revisit if a phone test shows the 4B under ~15 s per answer on the target
device; switching is one line in `lib/data/ai/model_catalog.dart`
(`ModelCatalog.llm`) plus `docs/AI_DISCLOSURE.md`.

¹ One 4B answer (q19) cites RA 10913 Sec. 8 — that's the legal basis of the
Distracted-driving fine shown on screen, which the guard allows by design, so
it's not invented. It's still wrong *in context* because q19 retrieved the
wrong fines (see Known failures). The first eval run counted it as invented;
`run_eval.dart` now uses the guard's definition (shown laws + shown fines' RA
basis).

## 2. How to run (Windows PC, Git Bash)

### Download the models (once, ~3.7 GB, into the git-ignored `models/`)

```bash
mkdir -p models && cd models
curl -L -C - -O https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf
curl -L -C - -O https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/embeddinggemma-300M-Q8_0.gguf
# optional, for the 1B vs 4B comparison:
curl -L -C - -O https://huggingface.co/ggml-org/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf
cd ..
```

All public and ungated (no Hugging Face token). Never commit them.

### Run the eval

```bash
flutter pub get

# Retrieval only (fast, ~1 min): main set, then held-out set
dart run tools/eval/run_eval.dart --label main --retriever hybrid
dart run tools/eval/run_eval.dart --label holdout --retriever hybrid --set tools/eval/holdout.json

# With real answers from the LLM (~3 min for 1B, ~10 min for 4B)
dart run tools/eval/run_eval.dart --label main-1b --retriever hybrid \
    --llm models/gemma-3-1b-it-Q4_K_M.gguf

# Old keyword-only behaviour, for comparison
dart run tools/eval/run_eval.dart --label fts
```

Defaults: `--embedder models/embeddinggemma-300M-Q8_0.gguf`,
`--embeddings assets/data/embeddings.json`, `--set tools/eval/questions.json`.

Gotcha (Windows): only one `dart run` / `flutter test` at a time — they share
`.dart_tool/lib/*.dll`, and a second one fails with `PathAccessException:
Cannot delete file … ggml.dll`. If a stopped run leaves an orphaned
`dart.exe … run_eval.dart`, end that process.

### Read the output

Per question:

```
MISS q19 [enforcer] Kaskasero daw ako magmaneho sabi ng pulis
     laws: ra10913-s6, ra10586-s12, ra10586-s6  (want ra4136-s48: MISS)
     fines: Driving under the influence…; Distracted driving…  (want Reckless: MISS)
     answer (5010ms): …the "Pagsusuri" the LLM wrote…
```

- `HIT`/`MISS` — all expectations met or not.
- `laws:` — the cited section ids in order (`ra4136-s48` = RA 4136 Sec. 48).
- `fines:` — cited fines (violation name).
- `answer` — only the LLM's "Pagsusuri" part, with total answer time.

Summary at the end: retrieval accuracy, law/fine hit rates, retrieval time,
answer time, "analysis cites an expected section", "analysis invents a
citation". Full details go to `tools/eval/results/<label>.json` (the `.log`
files are git-ignored; redirect stdout if you want to keep one).

### After changing laws.json / fines.json / faq.json

```bash
dart run tools/build_embeddings.dart     # ~40 s; rewrites assets/data/embeddings.json
flutter test test/data                    # fails if embeddings are stale
```

The app ignores a stale `embeddings.json` (hash mismatch) and silently falls
back to keyword-only retrieval — so always rebuild.

## 3. How retrieval works now — and where to edit

```
question ──► classifyIntent ─┐
          ├► FTS5 (keywords + Tagalog roots + synonyms) ─┐
          ├► embed question (EmbeddingGemma) ─► cosine vs pre-embedded laws/fines/FAQ ─┤
          │                                                                          ▼
          └───────────────────────────────────────────────────►  RRF fusion + intent boost/anchors
                                                                  ▼
                                    top 3 laws + top 2 fines ─► answer (code writes Batas;
                                                                LLM writes Pagsusuri ─► citation guard)
```

| Piece | What it does | File |
|---|---|---|
| Intent routing | Keyword rules → `fine`, `accident`, `enforcer`, `rightOfWay`, `general`. Also the per-intent **preferred sections** (×1.25 boost) and **anchors** (always a candidate: accident → Sec. 55, right of way → Sec. 42). | `lib/data/rag/intent.dart` |
| Keyword search | FTS5/bm25. `expandQuery` adds English law words for Taglish words (`_synonyms`). Penalty-section logic for keyword-only mode. | `lib/data/rag/law_retriever.dart` |
| Tagalog roots | `tagalogRoots()`: one prefix (naka-, nag-, mag-, na-, ma-…), -um-/-in- infix, reduplication. Used in FTS queries and appended to indexed fine aliases / law tags. | `lib/data/local/fts_query.dart`, `AppDatabase.withRoots` in `lib/data/local/app_database.dart` (bump `schemaVersion` if you change indexing) |
| Embeddings | `EmbeddingSpec` (query/doc prompt formats), `LlamaTextEmbedder` (llama.cpp) | `lib/data/rag/text_embedder.dart` |
| Pre-embedded docs | What text is embedded for each law (citation + title + text + tags), fine (violation + aliases — **not** the legal basis, it swamps the meaning), FAQ phrasing (as a query); fine→law links (top-2 nearest non-boilerplate sections) | `tools/build_embeddings.dart` |
| Vector search | Loads the asset, cosine top-k, fine→law links, FAQ | `lib/data/rag/vector_index.dart` |
| Fusion | Reciprocal rank fusion (`_rrfK = 20`, depth 15). Laws: FTS + vectors + FAQ (×2, only if similarity ≥ `faqThreshold` 0.62) + laws cited by matched fines (×1.5) + anchors, then intent boost. Fines: ranked by **violation type** (agency/offense duplicates collapsed), semantic side ×0.5, then the row of the agency the driver named. Enforcer-only questions show a fine only if keyword top-5 and semantic top-8 agree. | `lib/data/rag/hybrid_retriever.dart` |
| FAQ boost | Devin's `assets/data/faq.json` (`[{question, aliases, sections}]`) — each question/alias is embedded; a strong match adds its `sections`. Not present yet: drop the file in and rebuild embeddings. | `tools/build_embeddings.dart`, `hybrid_retriever.dart` |
| Answer + LLM prompt | Code writes Kalma / Batas / Gagawin; LLM writes only Pagsusuri. Prompt rules in `_rules` / `askSystem` / `twoSidesSystem`. | `lib/data/ai/answer_parts.dart`, `lib/data/ai/local_ai_assistant.dart` |
| Citation guard | Streams the analysis sentence by sentence; replaces any RA citation not among the shown laws (or a shown fine's RA legal basis) with "ang batas sa itaas". The prompt no longer contains a fixed example citation — the 1B copied it ("RA 8750 Sec. 44"). | `lib/data/ai/citation_guard.dart` |
| Wiring | Hybrid is used when the embedder file is downloaded and the asset matches the data; otherwise keyword-only. Per-model readiness (`ModelManager.has`). | `lib/data/local/local_data.dart`, `lib/data/ai/model_catalog.dart`, `lib/data/ai/local_model_manager.dart` |
| Tests | Hybrid/roots/intent/FAQ/fallback/stale-asset guard; citation guard | `test/data/hybrid_retriever_test.dart`, `test/data/citation_guard_test.dart` |

## 4. Known failures (every question still missing)

### Main set (4/30)

| Id | Question | Expected | Got | Why |
|---|---|---|---|---|
| q12 | Magkano ang multa sa overspeeding? | RA 4136 Sec. 35/36 + Overspeeding fine | Fine ✓; laws Sec. 40, RA 10586 Sec. 12, Sec. 48 | "overspeeding" has no keyword overlap with "speed" (prefix match only works one way), and the precomputed fine→law link for Overspeeding points to Sec. 40/48, not Sec. 35. Fix: synonym `overspeeding → speed`, or an FAQ entry linking speed fines to Sec. 35/36. |
| q18 | Nag-counterflow ako…, magkano multa? | RA 4136 Sec. 37 + counterflow fine | Fine ✓; laws Sec. 54, 41, 48 | Conceptual link (counterflow = not keeping right) that neither keywords nor embeddings make. Fix: FAQ entry → `ra4136-s37`, or synonym `counterflow → right side of highway`. |
| q19 | Kaskasero daw ako magmaneho sabi ng pulis | RA 4136 Sec. 48 + Reckless fine | Distracted / DUI fines and their laws | Enforcer-only question → consensus fines. The root `magmaneho → maneho` also matches the aliases of distracted/drunk driving ("habang nagmamaneho"), crowding out Reckless; "kaskasero" isn't in `_synonyms`. Fix: treat `maneho` as a stopword-like generic verb in roots, and/or synonym `kaskasero → reckless`. |
| q23 | Required ba magpa-drug test at alcohol test pag naaksidente? | RA 10586 Sec. 7 | RA 10586 Sec. 5, 12; RA 4136 Sec. 53 | "drug test" makes it enforcer → a DUI fine is pulled in, and its legal basis (RA 10586 Sec. 12) is boosted into the laws, pushing out Sec. 7 (testing after accidents). Fix: only let fines push laws when the driver asked about a fine (not for enforcer-only), or an FAQ entry → `ra10586-s7`. |

### Held-out (2/10) — don't fix these by tuning on them

| Id | Question | Expected | Got | Why |
|---|---|---|---|---|
| h02 | Sira ang headlight ko, bawal ba magmaneho sa gabi? | RA 4136 Sec. 34 + defective accessories fine | Law ✓; no fine | "bawal ba" isn't a fine/enforcer intent, so no fine is shown. Product decision: should "bawal ba" questions show the fine? If yes, add a similar question to the **main** set first, then change the intent rules. |
| h04 | Ilang taon dapat ang bata para makaangkas sa motor? | "Child passenger on motorcycle" fine | No fine; helmet law sections | Same intent issue, **and a data gap**: RA 10666 (Children's Safety on Motorcycles Act), which this fine cites, is not in `laws.json`. Ask Devin to add it. |

### Answer quality (both models)

- The 1B rarely cites a section in its own analysis (3.6%). That's acceptable
  because the code-written "Ano ang sinasabi ng batas" section always shows
  the retrieved law with its real citation; but analyses can be generic.
- Without the guard, the 1B invented a citation in 13.3% of answers.
  Keep the guard on regardless of model.

## 5. Rules

1. **Never tune on the held-out set** (`tools/eval/holdout.json`). Don't read
   its misses to pick synonyms/thresholds. If you want a case like it covered,
   write a *new* question into `questions.json` and tune on that.
2. **Re-run both sets after every change** (retrieval-only is ~1 min each)
   and note both numbers in the commit message. A change that helps the main
   set but drops the held-out set is overfitting — revert it.
3. Rebuild `assets/data/embeddings.json` after any data change; `flutter test`
   must pass (it checks the asset matches the data).
4. Keep the citation guard on; never let the LLM write the Batas section.
5. Before a PR: `flutter analyze` clean, `flutter test` passing,
   `flutter build apk --debug` succeeds; update `docs/AI_DISCLOSURE.md` if a
   model changes.

## 6. Tuning log (`backend/ai-tuning`)

Targets: main ≥ 90%, held-out ≥ 80%, the 4 demo questions (`tools/eval/demo.json`)
correct on every run (retrieval + answer quality, 3 runs with the 1B).
Answer quality (`tools/eval/answer_quality.dart`): 4 headers once and in order;
no blame sentence (code's neutral frame excepted); expected law and fine shown
in "Ano ang sinasabi ng batas"; no invented citation; every peso amount in the
analysis appears in the shown law/fines.

| Step | Main (30) | Held-out (10) | Demo, 3 runs (1B) |
|---|---|---|---|
| Baseline on `main` (reproduced) | 86.7% (26/30) | 80.0% (8/10) | 4/4 retrieval, 4/4 quality, every run |
| 1. Enforcer-only fines no longer push their laws (q23 fixed) | 90.0% (27/30) | 80.0% (8/10) | 4/4 retrieval |
| 2. Fine→law links: tag/title evidence re-ranks each fine's top-6 nearest sections (embeddings rebuilt; q12 fixed) | 93.3% (28/30) | 80.0% (8/10) | 4/4 retrieval |
