import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../core/contracts/contracts.dart';
import '../local/app_database.dart';
import '../local/fts_query.dart';

/// Fines from assets/data/fines.json, searched with FTS5 (violation + aliases).
class SqliteFinesRepository implements FinesRepository {
  SqliteFinesRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Fine>> search(String query, Agency agency) async {
    final match = ftsQuery(query);
    final ResultSet rows;
    if (match == null) {
      rows = _database.db.select(
        'SELECT * FROM fines WHERE agency = ? ORDER BY id',
        [agency.toJson()],
      );
    } else {
      // Aliases carry the Taglish wording, so they weigh more than the title.
      rows = _database.db.select(
        'SELECT f.* FROM fines_fts '
        'JOIN fines f ON f.id = fines_fts.rowid '
        'WHERE fines_fts MATCH ? AND f.agency = ? '
        'ORDER BY bm25(fines_fts, 1.0, 2.0)',
        [match, agency.toJson()],
      );
    }
    return rows.map(fineFromRow).toList(growable: false);
  }

  static Fine fineFromRow(Row r) => Fine(
    violation: r['violation'] as String,
    agency: Agency.fromJson(r['agency'] as String),
    amount: r['amount'] as num,
    legalBasis: r['legal_basis'] as String,
    aliases: (jsonDecode(r['aliases'] as String) as List<dynamic>)
        .cast<String>()
        .toList(growable: false),
  );
}
