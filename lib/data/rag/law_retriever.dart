import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../core/contracts/contracts.dart';
import '../local/app_database.dart';
import '../local/fts_query.dart';
import '../repositories/sqlite_fines_repository.dart';

/// Local RAG retrieval: FTS5 + bm25 over laws.json and fines.json.
class LawRetriever {
  LawRetriever(this._database);

  final AppDatabase _database;

  /// Best-matching law chunks. Tags (Taglish keywords) weigh most, then the
  /// section title, then the English law text. With [aboutFine], sections on
  /// the same topic that also mention a penalty come first; other laws'
  /// penalty sections are never pulled in by the penalty words alone.
  List<LawChunk> laws(String question, {int k = 3, bool aboutFine = false}) {
    final topic = ftsQuery(expandQuery(question));
    if (topic == null) return const [];
    final seen = <String>{};
    return [
      if (aboutFine) ..._search('($topic) AND ($_penalty)', k * 4),
      ..._search(topic, k * 4),
    ]
        .where((c) => !_boilerplate.hasMatch(c.title) && seen.add(c.id))
        .take(k)
        .toList(growable: false);
  }

  static final _penalty = ftsQuery('penalty penalties fined fines')!;

  List<LawChunk> _search(String match, int limit) => _database.db
      .select(
        'SELECT l.* FROM laws_fts JOIN laws l ON l.rowid = laws_fts.rowid '
        'WHERE laws_fts MATCH ? '
        'ORDER BY bm25(laws_fts, 2.0, 1.0, 4.0) LIMIT ?',
        [match, limit],
      )
      .map(_toChunk)
      .toList(growable: false);

  /// Law chunks for [ids], in the given order (unknown ids are skipped).
  List<LawChunk> lawsByIds(List<String> ids) {
    if (ids.isEmpty) return const [];
    final rows = _database.db.select(
      'SELECT * FROM laws WHERE id IN (${List.filled(ids.length, '?').join(',')})',
      ids,
    );
    final byId = {for (final r in rows) r['id'] as String: _toChunk(r)};
    return [for (final id in ids) ?byId[id]];
  }

  /// FTS-ranked fine row ids (fines.json order, 1-based) for [question].
  List<int> fineRows(String question, {int k = 15}) {
    final match = ftsQuery(question);
    if (match == null) return const [];
    return _database.db
        .select(
          'SELECT f.id FROM fines_fts JOIN fines f ON f.id = fines_fts.rowid '
          'WHERE fines_fts MATCH ? '
          'ORDER BY bm25(fines_fts, 1.0, 2.0) LIMIT ?',
          [match, k],
        )
        .map((r) => r['id'] as int)
        .toList(growable: false);
  }

  /// Fines for row ids, in the given order.
  List<Fine> finesByRows(List<int> rows) {
    if (rows.isEmpty) return const [];
    final result = _database.db.select(
      'SELECT * FROM fines WHERE id IN (${List.filled(rows.length, '?').join(',')})',
      rows,
    );
    final byRow = {
      for (final r in result)
        r['id'] as int: SqliteFinesRepository.fineFromRow(r),
    };
    return [for (final row in rows) ?byRow[row]];
  }

  static bool isBoilerplate(String title) => _boilerplate.hasMatch(title);

  /// Sections that never answer a driver's question.
  static final _boilerplate = RegExp(
    r'^(short title|title of (the )?act|separability|repealing|effectivity'
    r'|appropriations?|implementing rules)',
    caseSensitive: false,
  );

  /// Taglish words → the English wording used in the law texts.
  static const _synonyms = {
    'seatbelt': 'seat belt',
    'selpon': 'mobile phone',
    'cellphone': 'mobile phone',
    'cp': 'mobile phone',
    'nagte-text': 'texting mobile',
    'text': 'mobile',
    'lasing': 'drunk alcohol',
    'nakainom': 'drunk alcohol',
    'alak': 'alcohol',
    'pasahero': 'passenger',
    'anak': 'child',
    'bata': 'child',
    'motor': 'motorcycle',
    'kotse': 'vehicle',
    'pumarada': 'parking',
    'parada': 'parking',
    'kumanan': 'turn right',
    'kumaliwa': 'turn left',
    'liko': 'turn',
    'bilis': 'speed',
    'mabilis': 'speed',
    'lisensya': 'license',
    'rehistro': 'registration',
    'bangga': 'collision accident',
    'nabangga': 'collision accident',
    'nagkabanggaan': 'collision accident',
    'aksidente': 'accident',
    'bangketa': 'sidewalk',
    'kalsada': 'highway',
    'preno': 'brakes',
    'busina': 'horn',
    'ilaw': 'lights',
    'tawiran': 'pedestrian crossing',
    'tumawid': 'pedestrian crossing',
    'pulis': 'police',
    'plaka': 'number plates',
  };

  /// Adds the law-text wording for Taglish words in [question].
  static String expandQuery(String question) {
    final words = question
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}-]+', unicode: true));
    // Roots too: "nakaparada" → "parada" → "parking".
    final extra = <String>{
      for (final w in words) ...[
        ?_synonyms[w],
        for (final r in tagalogRoots(w)) ?_synonyms[r],
      ],
    };
    return extra.isEmpty ? question : '$question ${extra.join(' ')}';
  }

  /// Best-matching fines across all agencies.
  List<Fine> fines(String question, {int k = 2}) {
    final match = ftsQuery(question);
    if (match == null) return const [];
    return _database.db
        .select(
          'SELECT f.* FROM fines_fts JOIN fines f ON f.id = fines_fts.rowid '
          'WHERE fines_fts MATCH ? '
          'ORDER BY bm25(fines_fts, 1.0, 2.0) LIMIT ?',
          [match, k],
        )
        .map(SqliteFinesRepository.fineFromRow)
        .toList(growable: false);
  }

  static LawChunk _toChunk(Row r) => LawChunk(
    id: r['id'] as String,
    source: r['source'] as String,
    section: r['section'] as String,
    title: r['title'] as String,
    text: r['text'] as String,
    tags: (jsonDecode(r['tags'] as String) as List<dynamic>)
        .cast<String>()
        .toList(growable: false),
  );
}
