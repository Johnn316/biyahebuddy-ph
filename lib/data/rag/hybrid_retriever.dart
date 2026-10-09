import '../../core/contracts/contracts.dart';
import 'intent.dart';
import 'law_retriever.dart';
import 'text_embedder.dart';
import 'vector_index.dart';

/// Laws and fines an answer cites.
typedef Retrieved = ({List<LawChunk> laws, List<Fine> fines});

/// Why retrieval chose what it did (debug/eval only, see [HybridRetriever.onTrace]).
typedef RetrievalTrace = ({
  Set<Intent> intents,
  bool asksFine,
  bool enforcerOnly,
  List<({String id, double score})> laws,
  List<({String violation, double score})> fines,
  List<({String text, double score, List<String> sections})> faq,
});

/// Hybrid retrieval: FTS5 keywords + semantic vectors (multilingual
/// embeddings), fused with reciprocal rank fusion, steered by intent and
/// boosted by strong FAQ matches. Falls back to keywords alone if the
/// embedder is missing or fails.
class HybridRetriever {
  HybridRetriever({
    required this.keyword,
    required this.index,
    required this.embedder,
    this.lawsK = 3,
    this.finesK = 2,
  }) : assert(index.modelId == embedder.spec.id, 'asset/model mismatch');

  final LawRetriever keyword;
  final VectorIndex index;
  final TextEmbedder embedder;
  final int lawsK;
  final int finesK;

  /// RRF constant: smaller = top ranks count more.
  static const _rrfK = 20;

  /// Candidate depth per ranked list.
  static const _depth = 15;

  /// An FAQ phrasing at least this similar to the question counts as a
  /// strong match and pulls in its linked sections.
  static const faqThreshold = 0.62;

  /// Score multiplier for laws that fit the question's intent.
  static const _intentBoost = 1.25;

  /// Debug/eval hook (tools/eval/ask.dart): called after each retrieval with
  /// the fused scores. Null in the app; never changes the result.
  void Function(RetrievalTrace trace)? onTrace;
  List<({String id, double score})> _traceLaws = const [];
  List<({String violation, double score})> _traceFines = const [];
  List<({String text, double score, List<String> sections})> _traceFaq =
      const [];

  Future<Retrieved> retrieve(String question, {required bool aboutFine}) async {
    final intents = classifyIntent(question);
    final asksFine = aboutFine || intents.contains(Intent.fine);
    // Flagged by an enforcer without asking "magkano": a fine likely applies,
    // but only show one that keyword AND semantic search both agree on.
    final enforcerOnly = !asksFine && intents.contains(Intent.enforcer);
    final vectors = await _embedAll([question]);

    // Fines first: they also tell us which law they cite.
    final fines = asksFine || enforcerOnly
        ? _fines(question, vectors, consensusOnly: enforcerOnly)
        : const <(int, Fine)>[];
    final laws = _laws(
      question,
      vectors,
      intents,
      // A fine brings its topic sections (fine→law links). Its penalty
      // provision (legal basis) only when the driver asked about a fine:
      // for "na-flag ako…" it pushed out the rule actually asked about.
      citedByFines: [
        for (final (row, f) in fines) ...[
          if (!enforcerOnly) ...lawIdsInLegalBasis(f.legalBasis),
          ...index.lawsForFine(row - 1),
        ],
      ],
    );
    _emitTrace(intents, asksFine: asksFine, enforcerOnly: enforcerOnly);
    return (laws: laws, fines: [for (final (_, f) in fines) f]);
  }

  void _emitTrace(
    Set<Intent> intents, {
    required bool asksFine,
    required bool enforcerOnly,
  }) {
    onTrace?.call((
      intents: intents,
      asksFine: asksFine,
      enforcerOnly: enforcerOnly,
      laws: _traceLaws,
      fines: _traceFines,
      faq: _traceFaq,
    ));
    _traceFines = const [];
  }

  Future<Retrieved> retrieveTwoSides(String driverA, String driverB) async {
    final both = '$driverA\n$driverB';
    final intents = classifyIntent(both)
      ..remove(Intent.general)
      ..add(Intent.accident);
    final vectors = await _embedAll([driverA, driverB, both]);
    final laws = _laws(both, vectors, intents, citedByFines: const []);
    _emitTrace(intents, asksFine: false, enforcerOnly: false);
    return (laws: laws, fines: const <Fine>[]);
  }

  Future<List<List<double>>> _embedAll(List<String> texts) async {
    try {
      return [
        for (final t in texts) await embedder.embed(embedder.spec.query(t)),
      ];
    } on Object {
      return const []; // keyword-only fallback
    }
  }

  List<LawChunk> _laws(
    String question,
    List<List<double>> vectors,
    Set<Intent> intents, {
    required List<String> citedByFines,
  }) {
    final scores = <String, double>{};
    void addRanked(Iterable<String> ids, {double weight = 1}) {
      var rank = 0;
      for (final id in ids) {
        scores[id] = (scores[id] ?? 0) + weight / (_rrfK + rank++);
      }
    }

    // Keyword side: topic only. Penalty sections come from the matched fines'
    // own legal basis (citedByFines), not from "penalty" words, which pulled
    // in other laws' penalty sections.
    addRanked(keyword.laws(question, k: _depth).map((c) => c.id));
    // The canonical section for the situation is always a candidate.
    addRanked([for (final i in intents) ...?intentAnchors[i]]);
    final faqSeen = <({String text, double score, List<String> sections})>[];
    for (final v in vectors) {
      addRanked(index.topLaws(v, _depth).map((e) => e.id));
      final top = index.topFaq(v, 3);
      if (onTrace != null) faqSeen.addAll(top);
      final faq = top
          .where((f) => f.score >= faqThreshold)
          .expand((f) => f.sections);
      addRanked(faq, weight: 2);
    }
    addRanked(citedByFines, weight: 1.5);

    final preferred = {for (final i in intents) ...?intentSections[i]};
    if (preferred.isNotEmpty) {
      for (final id in scores.keys.toList()) {
        if (preferred.contains(_baseId(id))) {
          scores[id] = scores[id]! * _intentBoost;
        }
      }
    }

    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    if (onTrace != null) {
      _traceLaws = [
        for (final id in ranked.take(8)) (id: id, score: scores[id]!),
      ];
      _traceFaq = faqSeen;
    }
    final chunks = keyword.lawsByIds(ranked.take(lawsK * 3).toList());
    final seenSections = <String>{};
    return chunks
        .where((c) => !LawRetriever.isBoilerplate(c.title))
        // One part per multi-part section ("ra4136-s34-p2" → "ra4136-s34").
        .where((c) => seenSections.add(_baseId(c.id)))
        .take(lawsK)
        .toList(growable: false);
  }

  /// (fines.json row 1-based, fine), best first.
  List<(int, Fine)> _fines(
    String question,
    List<List<double>> vectors, {
    required bool consensusOnly,
  }) {
    final fts = keyword.fineRows(question, k: _depth);
    final semantic = [
      for (final v in vectors)
        index.topFines(v, _depth).map((e) => e.index + 1).toList(),
    ];
    final candidates = {...fts, for (final l in semantic) ...l}.toList();
    final fineByRow = {
      for (final (i, f) in keyword.finesByRows(candidates).indexed)
        candidates[i]: f,
    };

    // Rank violation TYPES, not rows: one violation appears once per agency
    // and offense level, and those duplicates would otherwise outvote a
    // single strong match.
    String family(int row) => fineByRow[row]!.violation.split(' — ').first;
    List<String> families(List<int> rows) =>
        <String>{for (final r in rows) family(r)}.toList();

    final scores = <String, double>{};
    void addRanked(List<String> fams, {double weight = 1}) {
      for (final (rank, f) in fams.indexed) {
        scores[f] = (scores[f] ?? 0) + weight / (_rrfK + rank);
      }
    }

    final ftsFams = families(fts);
    addRanked(ftsFams);
    final semanticTop = <String>{};
    for (final rows in semantic) {
      final fams = families(rows);
      semanticTop.addAll(fams.take(8));
      // Fine vectors separate weakly (similar scores), so half weight.
      addRanked(fams, weight: 0.5);
    }
    var ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    if (onTrace != null) {
      _traceFines = [
        for (final f in ranked.take(5)) (violation: f, score: scores[f]!),
      ];
    }
    if (consensusOnly) {
      final ftsTop = ftsFams.take(5).toSet();
      // Keyword evidence that names exactly one violation type in its top 5
      // rows ("kaskasero" → Reckless only) is unambiguous on its own.
      final topRows = families(fts.take(5).toList());
      final unanimous = fts.length >= 2 && topRows.length == 1
          ? topRows.toSet()
          : const <String>{};
      ranked = [
        for (final f in ranked)
          if (unanimous.contains(f) ||
              (ftsTop.contains(f) && semanticTop.contains(f)))
            f,
      ];
    }

    // One row per type: the agency the driver named, else the best-ranked.
    final agency = _agencyIn(question);
    final order = [...fts, for (final l in semantic) ...l];
    return [
      for (final fam in ranked.take(finesK))
        () {
          final rows = order.where((r) => family(r) == fam).toList();
          final row = rows.firstWhere(
            (r) => agency != null && fineByRow[r]!.agency == agency,
            orElse: () => rows.first,
          );
          return (row, fineByRow[row]!);
        }(),
    ];
  }

  static Agency? _agencyIn(String question) {
    final t = question.toLowerCase();
    if (t.contains('mmda')) return Agency.mmda;
    if (RegExp(r'lto').hasMatch(t)) return Agency.lto;
    if (RegExp(r'(city|lungsod|munisipyo|qc|quezon city)').hasMatch(t)) {
      return Agency.city;
    }
    return null;
  }

  static String _baseId(String id) => id.replaceFirst(RegExp(r'-p\d+$'), '');
}
