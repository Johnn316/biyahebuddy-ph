import 'dart:convert';

import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/text_embedder.dart';
import 'package:biyahebuddy_ph/data/rag/vector_index.dart';
import 'package:biyahebuddy_ph/data/repositories/hybrid_fines_repository.dart';
import 'package:biyahebuddy_ph/data/repositories/sqlite_fines_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// "sumalubong" means counterflow; everything else means nothing.
class _Embedder implements TextEmbedder {
  @override
  EmbeddingSpec get spec => EmbeddingSpec.embeddingGemma;

  @override
  Future<List<double>> embed(String text) async => text.contains('sumalubong')
      ? const [1.0, 0.0, 0.0]
      : const [0.0, 0.0, 1.0];
}

void main() {
  final fines = jsonEncode([
    {
      'violation': 'Illegal counterflow',
      'agency': 'mmda',
      'amount': 2000,
      'legal_basis': 'Metro Manila Traffic Code',
      'aliases': ['counterflow'],
    },
    {
      'violation': 'Illegal parking',
      'agency': 'mmda',
      'amount': 1000,
      'legal_basis': 'Metro Manila Traffic Code',
      'aliases': ['illegal parking'],
    },
    {
      'violation': 'Illegal counterflow',
      'agency': 'city',
      'amount': 2000,
      'legal_basis': 'QC Ordinance',
      'aliases': ['counterflow'],
    },
  ]);
  final index = VectorIndex.fromJson(
    jsonEncode({
      'model': EmbeddingSpec.embeddingGemma.id,
      'dims': 3,
      'source_hash': 0,
      'laws': <String, String>{},
      'fines': [
        VectorIndex.encode(const [1.0, 0.0, 0.0]),
        VectorIndex.encode(const [0.0, 1.0, 0.0]),
        VectorIndex.encode(const [1.0, 0.0, 0.0]),
      ],
    }),
  );

  late AppDatabase db;
  setUp(
    () => db = AppDatabase.open(':memory:', lawsJson: '[]', finesJson: fines),
  );
  tearDown(() => db.close());

  HybridFinesRepository repo({bool ready = true}) => HybridFinesRepository(
    keyword: SqliteFinesRepository(db),
    database: db,
    index: index,
    embedder: _Embedder(),
    isReady: () => ready,
  );

  test('empty query → every fine of the agency', () async {
    final all = await repo().search('', Agency.mmda);
    expect(all.map((f) => f.violation), [
      'Illegal counterflow',
      'Illegal parking',
    ]);
  });

  test('paraphrase with no keyword overlap is found semantically, '
      'only for the chosen agency', () async {
    final r = await repo().search(
      'sumalubong ako sa kabilang lane',
      Agency.mmda,
    );
    expect(r.map((f) => f.violation), ['Illegal counterflow']);
    expect(r.single.agency, Agency.mmda);
  });

  test('keyword match still works; unrelated text finds nothing', () async {
    expect(
      (await repo().search('illegal parking', Agency.mmda)).first.violation,
      'Illegal parking',
    );
    expect(await repo().search('zxqv blorp', Agency.mmda), isEmpty);
  });

  test('without the embedding model → keyword only', () async {
    expect(
      await repo(ready: false).search('sumalubong ako', Agency.mmda),
      isEmpty,
    );
  });
}
