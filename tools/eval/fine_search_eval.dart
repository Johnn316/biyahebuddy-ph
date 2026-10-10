// Na-flag search eval: Taglish/English paraphrases → the right fine in the
// top 3, keyword-only (FTS5) vs hybrid (FTS5 + EmbeddingGemma).
//
//   dart run tools/eval/fine_search_eval.dart \
//       [--embedder models/embeddinggemma-300M-Q8_0.gguf]
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/text_embedder.dart';
import 'package:biyahebuddy_ph/data/rag/vector_index.dart';
import 'package:biyahebuddy_ph/data/repositories/hybrid_fines_repository.dart';
import 'package:biyahebuddy_ph/data/repositories/sqlite_fines_repository.dart';

/// (agency, query, expected substring of the violation; null = expect none)
const cases = <(Agency, String, String?)>[
  (Agency.mmda, 'nag-red light ako', 'traffic signs'),
  (Agency.lto, 'walang lisensya', 'license'),
  (Agency.mmda, 'illegal parking', 'parking'),
  (Agency.lto, 'nag cellphone ako habang nagmamaneho', 'Distracted'),
  (Agency.city, 'lumusot ako sa pula na ilaw', 'traffic signs'),
  (Agency.mmda, 'hindi naka seatbelt yung katabi ko', 'seatbelt'),
  (Agency.mmda, 'sumalubong ako sa kabilang lane', 'counterflow'),
  (Agency.lto, 'lasing daw ako sabi ng enforcer', 'influence'),
  (Agency.mmda, 'nakatsinelas ako sa motor', 'dress code'),
  (Agency.city, 'mabilis daw ako masyado', 'Overspeeding'),
  (Agency.mmda, 'nagbaba ako ng pasahero sa bawal', 'Loading'),
  (Agency.lto, 'yung bata walang car seat', 'child restraint'),
  (Agency.mmda, 'I ran a red light', 'traffic signs'),
  (Agency.lto, 'I was texting while driving', 'Distracted'),
  (Agency.mmda, 'went the wrong way on a one way street', 'counterflow'),
  (Agency.city, 'left my car on a no parking zone', 'parking'),
  (Agency.mmda, 'too many passengers in my van', 'Overloading'),
  (Agency.mmda, 'busina ko sira at walang side mirror', 'accessories'),
  (Agency.mmda, 'zxqv blorp', null),
  (Agency.lto, 'magandang tanawin sa bundok', null),
];

Future<void> main(List<String> args) async {
  final i = args.indexOf('--embedder');
  final embedderPath = i >= 0
      ? args[i + 1]
      : 'models/embeddinggemma-300M-Q8_0.gguf';
  final db = AppDatabase.open(
    ':memory:',
    lawsJson: File('assets/data/laws.json').readAsStringSync(),
    finesJson: File('assets/data/fines.json').readAsStringSync(),
  );
  final index = VectorIndex.fromJson(
    File('assets/data/embeddings.json').readAsStringSync(),
  );
  final embedder = LlamaTextEmbedder(
    spec: EmbeddingSpec.byId(index.modelId),
    modelPath: () async => embedderPath,
  );
  await embedder.load();
  final keyword = SqliteFinesRepository(db);
  final hybrid = HybridFinesRepository(
    keyword: keyword,
    database: db,
    index: index,
    embedder: embedder,
  );

  var ftsHits = 0, hyHits = 0;
  for (final (agency, q, want) in cases) {
    final fts = await keyword.search(q, agency);
    final hy = await hybrid.search(q, agency);
    // Top 3 distinct violation types (offense levels count once).
    List<String> types(List<Fine> r) =>
        {for (final f in r) f.violation.split(' — ').first}.toList();
    bool hit(List<Fine> r) => want == null
        ? r.isEmpty
        : types(r).take(3).any((v) => v.contains(want));
    if (hit(fts)) ftsHits++;
    if (hit(hy)) hyHits++;
    String top(List<Fine> r) => types(r).take(3).join(' | ');
    print('${hit(hy) ? 'HIT ' : 'MISS'} [${agency.name}] "$q" (want $want)');
    print('   fts:    ${hit(fts) ? 'hit ' : 'miss'} ${top(fts)}');
    print('   hybrid: ${hit(hy) ? 'hit ' : 'miss'} ${top(hy)}');
    if (args.contains('--scores')) {
      final v = await embedder.embed(embedder.spec.query(q));
      final rows = db.db
          .select('SELECT violation, agency FROM fines ORDER BY id')
          .toList();
      final top = [
        for (final s in index.topFines(v, 30))
          if (rows[s.index]['agency'] == agency.name)
            '${(rows[s.index]['violation'] as String).split(' (').first}'
                ' ${s.score.toStringAsFixed(2)}',
      ].take(3);
      print('   semantic: ${top.join(' | ')}');
    }
  }
  print('');
  print('FTS5 keyword: $ftsHits/${cases.length} in top 3');
  print('Hybrid:       $hyHits/${cases.length} in top 3');
  await embedder.dispose();
}
