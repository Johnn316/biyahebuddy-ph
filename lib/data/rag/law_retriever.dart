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
  };

  /// Adds the law-text wording for Taglish words in [question].
  static String expandQuery(String question) {
    final words = question
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}-]+', unicode: true));
    final extra = <String>{for (final w in words) ?_synonyms[w]};
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
