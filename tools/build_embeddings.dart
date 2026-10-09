// Precomputes semantic embeddings for laws.json, fines.json (and faq.json if
// present) into assets/data/embeddings.json. Runs on the PC with the same
// GGUF the app downloads; the phone then only embeds the question.
//
//   dart run tools/build_embeddings.dart \
//       --model models/embeddinggemma-300M-Q8_0.gguf \
//       --spec embeddinggemma-300m-q8
//
// Rerun whenever laws.json / fines.json / faq.json change: the app ignores
// an embeddings file whose source_hash doesn't match the bundled data.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biyahebuddy_ph/data/rag/text_embedder.dart';
import 'package:biyahebuddy_ph/data/rag/vector_index.dart';

Future<void> main(List<String> args) async {
  final opts = <String, String>{
    for (var i = 0; i + 1 < args.length; i += 2)
      args[i].replaceFirst('--', ''): args[i + 1],
  };
  final modelPath = opts['model'] ?? 'models/embeddinggemma-300M-Q8_0.gguf';
  final spec = EmbeddingSpec.byId(
    opts['spec'] ?? EmbeddingSpec.embeddingGemma.id,
  );
  final out = opts['out'] ?? 'assets/data/embeddings.json';

  final lawsJson = File('assets/data/laws.json').readAsStringSync();
  final finesJson = File('assets/data/fines.json').readAsStringSync();
  final faqFile = File('assets/data/faq.json');
  final faqJson = faqFile.existsSync() ? faqFile.readAsStringSync() : '[]';

  final embedder = LlamaTextEmbedder(
    spec: spec,
    modelPath: () async => modelPath,
  );
  final sw = Stopwatch()..start();
  await embedder.load();

  final laws = <String, String>{};
  for (final l
      in (jsonDecode(lawsJson) as List<dynamic>).cast<Map<String, dynamic>>()) {
    final citation =
        '${(l['source'] as String).split(' (').first} ${l['section']}';
    final tags = (l['tags'] as List<dynamic>? ?? const []).join(', ');
    final v = await embedder.embed(
      spec.doc('$citation ${l['title']}', '${l['text']}\nKeywords: $tags'),
    );
    laws[l['id'] as String] = VectorIndex.encode(v);
  }

  final fines = <String>[];
  for (final f
      in (jsonDecode(finesJson) as List<dynamic>)
          .cast<Map<String, dynamic>>()) {
    // Meaning only: the long legal-basis citation would swamp the vector.
    final aliases = (f['aliases'] as List<dynamic>? ?? const []).join('; ');
    final v = await embedder.embed(spec.doc(f['violation'] as String, aliases));
    fines.add(VectorIndex.encode(v));
  }

  // Fine → nearest law sections (doc-to-doc), so a matched MMDA/city fine
  // (whose legal basis is a local code, not an RA) still links to the law.
  final lawVecs = {
    for (final e in laws.entries)
      e.key: VectorIndex.fromJson(
        jsonEncode({
          'model': spec.id,
          'dims': 0,
          'source_hash': 0,
          'laws': {e.key: e.value},
          'fines': const [],
        }),
      ).laws[e.key]!,
  };
  final lawTitles = {
    for (final l
        in (jsonDecode(lawsJson) as List<dynamic>).cast<Map<String, dynamic>>())
      l['id'] as String: l['title'] as String,
  };
  final fineLaws = <List<String>>[];
  for (final fv in fines) {
    final f = Uint8List.fromList(base64Decode(fv)).buffer.asFloat32List();
    final scored = [
      for (final e in lawVecs.entries)
        if (!RegExp(
          r'^(short title|title of|declaration of policy|definition|penalt|'
          r'separability|repealing|effectivity|implementing|appropriation)',
          caseSensitive: false,
        ).hasMatch(lawTitles[e.key]!))
          (id: e.key, score: VectorIndex.dot(f, e.value)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    fineLaws.add([for (final s in scored.take(2)) s.id]);
  }

  // FAQ phrasings are questions, so embed them like queries.
  final faq = <Map<String, dynamic>>[];
  for (final q
      in (jsonDecode(faqJson) as List<dynamic>).cast<Map<String, dynamic>>()) {
    final sections = (q['sections'] as List<dynamic>).cast<String>();
    final phrasings = [
      q['question'] as String,
      ...(q['aliases'] as List<dynamic>? ?? const []).cast<String>(),
    ];
    for (final p in phrasings) {
      faq.add({
        'text': p,
        'sections': sections,
        'vec': VectorIndex.encode(await embedder.embed(spec.query(p))),
      });
    }
  }

  final dims = VectorIndex.fromJson(
    jsonEncode({
      'model': spec.id,
      'dims': 0,
      'source_hash': 0,
      'laws': {laws.keys.first: laws.values.first},
      'fines': const [],
    }),
  ).laws.values.first.length;

  File(out).writeAsStringSync(
    jsonEncode({
      'model': spec.id,
      'dims': dims,
      'source_hash': VectorIndex.hashSources(lawsJson, finesJson, faqJson),
      'built': DateTime.now().toUtc().toIso8601String(),
      'laws': laws,
      'fines': fines,
      'fine_laws': fineLaws,
      'faq': faq,
    }),
  );
  await embedder.dispose();
  stdout.writeln(
    'Wrote $out: ${laws.length} laws, ${fines.length} fines, '
    '${faq.length} FAQ phrasings, $dims dims, model ${spec.id} '
    '(${sw.elapsedMilliseconds} ms, ${File(out).lengthSync() ~/ 1024} KB)',
  );
  exit(0);
}
