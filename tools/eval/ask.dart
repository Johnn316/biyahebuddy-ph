// Interactive "ask Buddy" on the PC — fully offline, same pipeline as the app
// (intent routing, hybrid retrieval + FAQ boost, Gemma 3 1B, same prompts,
// same 4-section answer with citation guard).
//
//   dart run tools/eval/ask.dart
//   dart run tools/eval/ask.dart --llm models/gemma-3-4b-it-Q4_K_M.gguf
//
// Type a question or scenario (Taglish / Tagalog / English).
//   /two              Dalawang panig: asks Driver A, then Driver B
//   /bad <note>       saves the last question + your note to
//                     tools/eval/feedback.json (to fix and add to the eval set)
//   /quit             exit
//
// Models must already be in models/ (see docs/AI_HANDOFF.md). Nothing here
// touches the network.
import 'dart:convert';
import 'dart:io';

import 'package:biyahebuddy_ph/data/ai/answer_parts.dart';
import 'package:biyahebuddy_ph/data/ai/local_ai_assistant.dart';
import 'package:biyahebuddy_ph/data/ai/local_llm.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/hybrid_retriever.dart';

import 'eval_setup.dart';

const _feedbackPath = 'tools/eval/feedback.json';

Future<void> main(List<String> args) async {
  stdout.encoding = utf8;
  final opts = <String, String>{'retriever': 'hybrid'};
  for (var i = 0; i + 1 < args.length; i++) {
    if (args[i].startsWith('--')) opts[args[i].substring(2)] = args[++i];
  }
  final llmPath = opts['llm'] ?? 'models/gemma-3-1b-it-Q4_K_M.gguf';
  final embedderPath =
      opts['embedder'] ??= 'models/embeddinggemma-300M-Q8_0.gguf';
  for (final p in [llmPath, embedderPath]) {
    if (!File(p).existsSync()) {
      stderr.writeln('Missing $p — download it first (docs/AI_HANDOFF.md §2).');
      exit(1);
    }
  }

  stdout.writeln('Loading Buddy (offline)…');
  final load = Stopwatch()..start();
  final db = AppDatabase.open(
    ':memory:',
    lawsJson: File('assets/data/laws.json').readAsStringSync(),
    finesJson: File('assets/data/fines.json').readAsStringSync(),
  );
  final setup = await EvalSetup.create(db, opts);
  final hybrid = setup.hybrid!;
  final llm = LocalLlm(modelPath: () async => llmPath);
  await llm.load();
  final buddy = LocalAiAssistant(
    retriever: setup.keyword,
    hybrid: hybrid,
    llm: llm,
    isModelReady: () => true,
  );
  stdout.writeln(
    'Ready in ${load.elapsedMilliseconds} ms — ${setup.description}\n'
    'LLM: $llmPath\n'
    'Type a question. /two = Dalawang panig, /bad <note> = save feedback, '
    '/quit = exit.\n',
  );

  Map<String, dynamic>? last;
  while (true) {
    final line = _prompt('Ikaw> ');
    if (line == null || line == '/quit' || line == '/exit') break;
    if (line.isEmpty) continue;

    if (line.startsWith('/bad')) {
      final note = line.substring(4).trim();
      if (last == null) {
        stdout.writeln('Wala pang naitanong.\n');
      } else if (note.isEmpty) {
        stdout.writeln('Isulat kung ano ang mali: /bad <note>\n');
      } else {
        _saveFeedback({...last, 'note': note});
        stdout.writeln('Saved to $_feedbackPath\n');
      }
      continue;
    }

    String? driverA, driverB, question;
    if (line == '/two') {
      driverA = _prompt('Driver A (ikaw)> ');
      driverB = _prompt('Driver B (kabila)> ');
      if (driverA == null || driverB == null || driverA.isEmpty || driverB.isEmpty) {
        stdout.writeln('Kailangan ang kuwento ng dalawang driver.\n');
        continue;
      }
    } else if (line.startsWith('/')) {
      stdout.writeln('Commands: /two, /bad <note>, /quit\n');
      continue;
    } else {
      question = line;
    }

    // Capture the scores of the retrieval the answer itself uses.
    RetrievalTrace? trace;
    int? retrievalMs;
    final sw = Stopwatch()..start();
    hybrid.onTrace = (t) {
      trace = t;
      retrievalMs = sw.elapsedMilliseconds;
    };
    final stream = question != null
        ? buddy.ask(question)
        : buddy.analyzeTwoSides(driverA!, driverB!);

    final answer = StringBuffer();
    int? firstChunkMs;
    var headerPrinted = false;
    await for (final chunk in stream) {
      if (!headerPrinted) {
        firstChunkMs = sw.elapsedMilliseconds;
        _printTrace(trace, question ?? '$driverA\n$driverB');
        stdout.writeln('─── Buddy ${'─' * 60}');
        headerPrinted = true;
      }
      answer.write(chunk);
      stdout.write(chunk); // streams like the app
    }
    final totalMs = sw.elapsedMilliseconds;
    hybrid.onTrace = null;

    stdout.writeln(
      '\n${'─' * 70}\n'
      'retrieval ${retrievalMs ?? '-'} ms · first text ${firstChunkMs ?? '-'} ms · '
      'total $totalMs ms\n',
    );

    final t = trace;
    last = {
      'at': DateTime.now().toIso8601String(),
      'question': ?question,
      'driverA': ?driverA,
      'driverB': ?driverB,
      'intents': [if (t != null) for (final i in t.intents) i.name],
      'topLaws': [if (t != null) for (final l in t.laws.take(3)) l.id],
      'topFines': [if (t != null) for (final f in t.fines.take(2)) f.violation],
      'answer': answer.toString(),
    };
  }

  hybrid.onTrace = null;
  await llm.dispose();
  await setup.dispose();
  db.close();
  stdout.writeln('Paalam!');
  exit(0);
}

String? _prompt(String label) {
  stdout.write(label);
  return stdin.readLineSync(encoding: utf8)?.trim();
}

void _printTrace(RetrievalTrace? t, String text) {
  final aboutFine = AnswerParts.asksAboutFine(text);
  if (t == null) {
    stdout.writeln('(keyword-only retrieval — no scores)');
    return;
  }
  stdout.writeln(
    'intent: ${t.intents.map((i) => i.name).join(', ')}'
    '${aboutFine || t.asksFine ? ' · asks about a fine' : ''}'
    '${t.enforcerOnly ? ' · enforcer-only (fine needs keyword+semantic agreement)' : ''}',
  );
  stdout.writeln('top law candidates (fused score; first 3 non-boilerplate are cited):');
  for (final l in t.laws) {
    stdout.writeln('  ${l.score.toStringAsFixed(4)}  ${l.id}');
  }
  if (t.fines.isNotEmpty) {
    stdout.writeln('top fine types (fused score):');
    for (final f in t.fines) {
      stdout.writeln('  ${f.score.toStringAsFixed(4)}  ${f.violation}');
    }
  }
  final faq = {
    for (final f in t.faq) f.text: f,
  }.values.toList()..sort((a, b) => b.score.compareTo(a.score));
  for (final f in faq.take(2)) {
    final used = f.score >= HybridRetriever.faqThreshold ? 'USED' : 'below threshold';
    stdout.writeln(
      'faq ${f.score.toStringAsFixed(3)} ($used): "${f.text}" → ${f.sections.join(', ')}',
    );
  }
}

void _saveFeedback(Map<String, dynamic> entry) {
  final file = File(_feedbackPath);
  final list = file.existsSync() && file.readAsStringSync().trim().isNotEmpty
      ? (jsonDecode(file.readAsStringSync()) as List<dynamic>)
      : <dynamic>[];
  list.add(entry);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(list)}\n',
  );
}
