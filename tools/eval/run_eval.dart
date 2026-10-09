// Buddy eval harness — runs on the PC, no phone needed.
//
// Uses the SAME code as the app (AppDatabase, retriever, LocalAiAssistant,
// LocalLlm/llama.cpp) on the same assets and GGUF files, and scores
// retrieval against tools/eval/questions.json.
//
//   dart run tools/eval/run_eval.dart                       # retrieval only
//   ... --set tools/eval/holdout.json   (10 questions never used for tuning)
//   dart run tools/eval/run_eval.dart --llm models/gemma-3-1b-it-Q4_K_M.gguf
//   dart run tools/eval/run_eval.dart --retriever hybrid \
//       --embedder models/embeddinggemma-300M-Q8_0.gguf --llm ...
//
// A question passes when every expectation it has is met:
//   laws  — at least one expected section id is among the cited sections
//           ("ra4136-s34" also matches its parts "ra4136-s34-p2")
//   fines — at least one cited fine's violation contains an expected keyword
import 'dart:convert';
import 'dart:io';

import 'package:biyahebuddy_ph/data/ai/local_ai_assistant.dart';
import 'package:biyahebuddy_ph/data/ai/local_llm.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';

import 'eval_setup.dart';

Future<void> main(List<String> args) async {
  final opts = _parse(args);
  final label = opts['label'] ?? 'run';
  final questions =
      (jsonDecode(
                File(
                  opts['set'] ?? 'tools/eval/questions.json',
                ).readAsStringSync(),
              )
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  final db = AppDatabase.open(
    ':memory:',
    lawsJson: File('assets/data/laws.json').readAsStringSync(),
    finesJson: File('assets/data/fines.json').readAsStringSync(),
  );

  final llmPath = opts['llm'];
  final llm = llmPath == null ? null : LocalLlm(modelPath: () async => llmPath);
  final setup = await EvalSetup.create(db, opts);
  final assistant = LocalAiAssistant(
    retriever: setup.keyword,
    hybrid: setup.hybrid,
    llm: llm ?? _NoLlm(),
    isModelReady: () => llm != null,
  );

  if (llm != null) {
    final sw = Stopwatch()..start();
    await llm.load();
    stdout.writeln('LLM loaded in ${sw.elapsedMilliseconds} ms ($llmPath)');
  }
  stdout.writeln('Retriever: ${setup.description}\n');

  var passed = 0, lawTotal = 0, lawHits = 0, fineTotal = 0, fineHits = 0;
  var answered = 0, invented = 0, onTarget = 0, onTargetTotal = 0;
  final retrievalMs = <int>[];
  final answerMs = <int>[];
  final rows = <Map<String, dynamic>>[];

  for (final q in questions) {
    final text = q['question'] as String;
    final driverB = q['driverB'] as String?;
    final expLaws = (q['laws'] as List<dynamic>? ?? const []).cast<String>();
    final expFines = (q['fines'] as List<dynamic>? ?? const []).cast<String>();

    final rsw = Stopwatch()..start();
    final got = driverB == null
        ? await assistant.retrieve(text)
        : await assistant.retrieveTwoSides(text, driverB);
    retrievalMs.add(rsw.elapsedMilliseconds);

    final lawIds = [for (final l in got.laws) l.id];
    final fineNames = [for (final f in got.fines) f.violation];
    final lawHit = expLaws.isEmpty
        ? null
        : expLaws.any(
            (e) => lawIds.any((id) => id == e || id.startsWith('$e-p')),
          );
    final fineHit = expFines.isEmpty
        ? null
        : expFines.any(
            (e) =>
                fineNames.any((v) => v.toLowerCase().contains(e.toLowerCase())),
          );
    final ok = (lawHit ?? true) && (fineHit ?? true);
    if (lawHit != null) {
      lawTotal++;
      if (lawHit) lawHits++;
    }
    if (fineHit != null) {
      fineTotal++;
      if (fineHit) fineHits++;
    }
    if (ok) passed++;

    String? answer;
    int? ms;
    if (llm != null) {
      final sw = Stopwatch()..start();
      final full =
          await (driverB == null
                  ? assistant.ask(text)
                  : assistant.analyzeTwoSides(text, driverB))
              .join();
      ms = sw.elapsedMilliseconds;
      answerMs.add(ms);
      answer = _pagsusuri(full);
      // Citations the LLM wrote vs. what retrieval gave it.
      answered++;
      final cited = _citations(answer);
      final allowed = {for (final l in got.laws) _citationOf(l.id)};
      if (cited.any((c) => !allowed.contains(c))) invented++;
      if (expLaws.isNotEmpty) {
        onTargetTotal++;
        if (cited.any((c) => expLaws.map(_citationOf).contains(c))) onTarget++;
      }
    }

    stdout.writeln(
      '${ok ? 'HIT ' : 'MISS'} ${q['id']} [${q['intent']}] $text'
      '${driverB == null ? '' : ' || B: $driverB'}',
    );
    stdout.writeln(
      '     laws: ${lawIds.join(', ')}'
      '${expLaws.isEmpty ? '' : '  (want ${expLaws.join('/')}: ${_mark(lawHit)})'}',
    );
    if (fineNames.isNotEmpty || expFines.isNotEmpty) {
      stdout.writeln(
        '     fines: ${fineNames.map((v) => v.split(' — ').first).join('; ')}'
        '${expFines.isEmpty ? '' : '  (want ${expFines.join('/')}: ${_mark(fineHit)})'}',
      );
    }
    if (answer != null) {
      stdout.writeln('     answer (${ms}ms): ${_oneLine(answer)}');
    }
    stdout.writeln('');

    rows.add({
      'id': q['id'],
      'intent': q['intent'],
      'pass': ok,
      'lawHit': lawHit,
      'fineHit': fineHit,
      'laws': lawIds,
      'fines': fineNames,
      'answerMs': ms,
      'answer': answer,
    });
  }

  final n = questions.length;
  String pct(int a, int b) =>
      b == 0 ? '-' : '${(100 * a / b).toStringAsFixed(1)}% ($a/$b)';
  final summary = {
    'label': label,
    'retriever': setup.description,
    'llm': llmPath,
    'accuracy': passed / n,
    'lawHitRate': lawTotal == 0 ? null : lawHits / lawTotal,
    'fineHitRate': fineTotal == 0 ? null : fineHits / fineTotal,
    'retrievalMsMedian': _median(retrievalMs),
    'answerMsMedian': answerMs.isEmpty ? null : _median(answerMs),
    'answerMsMean': answerMs.isEmpty
        ? null
        : answerMs.reduce((a, b) => a + b) ~/ answerMs.length,
    'inventedCitationRate': answered == 0 ? null : invented / answered,
    'onTargetCitationRate': onTargetTotal == 0
        ? null
        : onTarget / onTargetTotal,
    'answerMsMax': answerMs.isEmpty
        ? null
        : answerMs.reduce((a, b) => a > b ? a : b),
  };

  stdout.writeln('=' * 72);
  stdout.writeln('[$label] ${setup.description}');
  stdout.writeln(
    'Retrieval accuracy (all expectations met): ${pct(passed, n)}',
  );
  stdout.writeln('  law section hit@cited:  ${pct(lawHits, lawTotal)}');
  stdout.writeln('  fine hit@cited:         ${pct(fineHits, fineTotal)}');
  stdout.writeln(
    '  retrieval time median:  ${summary['retrievalMsMedian']} ms',
  );
  if (answerMs.isNotEmpty) {
    stdout.writeln(
      '  answer time (PC CPU):   median ${summary['answerMsMedian']} ms, '
      'mean ${summary['answerMsMean']} ms, max ${summary['answerMsMax']} ms',
    );
    stdout.writeln(
      '  analysis cites an expected section: ${pct(onTarget, onTargetTotal)}',
    );
    stdout.writeln(
      '  analysis invents a citation (not retrieved): ${pct(invented, answered)}',
    );
  }

  Directory('tools/eval/results').createSync(recursive: true);
  File('tools/eval/results/$label.json').writeAsStringSync(
    const JsonEncoder.withIndent(
      '  ',
    ).convert({'summary': summary, 'questions': rows}),
  );
  await llm?.dispose();
  await setup.dispose();
  db.close();
  exit(0);
}

Map<String, String> _parse(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--') && i + 1 < args.length) {
      out[args[i].substring(2)] = args[++i];
    }
  }
  return out;
}

String _mark(bool? hit) => hit == null ? '-' : (hit ? 'hit' : 'MISS');

int _median(List<int> xs) {
  final s = [...xs]..sort();
  return s.isEmpty ? 0 : s[s.length ~/ 2];
}

String _pagsusuri(String full) {
  final start = full.indexOf('**Pagsusuri**');
  final end = full.indexOf('**Ano ang gagawin**');
  if (start < 0) return full;
  return full
      .substring(start + '**Pagsusuri**'.length, end < 0 ? full.length : end)
      .trim();
}

String _oneLine(String s) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length > 260 ? '${t.substring(0, 260)}…' : t;
}

/// Stand-in when no --llm is given (retrieval-only runs).
class _NoLlm implements TextGenerator {
  @override
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 160,
  }) => const Stream.empty();
}

/// "RA 4136 Sec. 44" / "R.A. 4136, Section 44" → "ra4136-s44".
Set<String> _citations(String text) => {
  for (final m in RegExp(
    r'R\.?\s?A\.?\s*(?:No\.?\s*)?(\d{3,5}),?\s*(?:Sec(?:tion)?\.?|Seksyon)\s*(\d+)',
    caseSensitive: false,
  ).allMatches(text))
    'ra${m[1]}-s${m[2]}',
};

/// "ra4136-s34-p2" → "ra4136-s34".
String _citationOf(String id) => id.replaceFirst(RegExp(r'-p\d+$'), '');
