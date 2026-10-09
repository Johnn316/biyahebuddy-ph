import '../../core/contracts/contracts.dart';
import '../local/app_database.dart';
import '../rag/text_embedder.dart';
import '../rag/vector_index.dart';
import 'sqlite_fines_repository.dart';

/// Na-flag search with the same hybrid idea as Buddy: FTS5 keywords
/// (violation + aliases) fused with semantic similarity over the bundled
/// fine embeddings, so Taglish/English paraphrases ("nag-red light ako",
/// "nag cellphone") find the right fine. Keyword-only when the embedding
/// model isn't downloaded (or fails).
///
/// Empty query → every fine of the agency, in fines.json order.
class HybridFinesRepository implements FinesRepository {
  HybridFinesRepository({
    required this.keyword,
    required AppDatabase database,
    this.index,
    this.embedder,
    bool Function()? isReady,
  }) : _database = database,
       isReady = isReady ?? (() => index != null && embedder != null);

  final SqliteFinesRepository keyword;
  final AppDatabase _database;
  final VectorIndex? index;
  final TextEmbedder? embedder;
  final bool Function() isReady;

  /// A semantic-only hit must be at least this similar to the query.
  /// Tuned with tools/eval/fine_search_eval.dart.
  static const semanticMin = 0.40;

  /// Semantic hits count half: keyword (alias) matches stay on top, the
  /// embeddings add paraphrases keywords miss.
  static const _semanticWeight = 0.5;

  /// RRF constant (same as the law retriever).
  static const _rrfK = 20;

  List<Fine>? _all;
  List<Fine> get _rows => _all ??= _database.db
      .select('SELECT * FROM fines ORDER BY id')
      .map(SqliteFinesRepository.fineFromRow)
      .toList(growable: false);

  @override
  Future<List<Fine>> search(String query, Agency agency) async {
    final kw = await keyword.search(query, agency);
    final q = query.trim();
    final idx = index;
    final emb = embedder;
    if (q.isEmpty || idx == null || emb == null || !isReady()) return kw;

    List<double> vec;
    try {
      vec = await emb.embed(emb.spec.query(q));
    } on Object {
      return kw;
    }
    final semantic = [
      for (final s in idx.topFines(vec, 40))
        if (s.score >= semanticMin &&
            s.index < _rows.length &&
            _rows[s.index].agency == agency)
          _rows[s.index],
    ];

    String key(Fine f) => '${f.agency.name}|${f.violation}';
    final scores = <String, double>{};
    final byKey = <String, Fine>{};
    void addRanked(List<Fine> list, {double weight = 1}) {
      for (final (rank, f) in list.indexed) {
        scores[key(f)] = (scores[key(f)] ?? 0) + weight / (_rrfK + rank);
        byKey[key(f)] = f;
      }
    }

    addRanked(kw);
    addRanked(semantic, weight: _semanticWeight);
    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return [for (final k in ranked) byKey[k]!];
  }
}
