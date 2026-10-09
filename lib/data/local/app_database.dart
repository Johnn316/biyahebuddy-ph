import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

/// Local sqlite DB built from the bundled JSON assets (laws.json, fines.json).
///
/// The DB is rebuilt whenever the asset content changes: a hash of the JSON
/// (plus [schemaVersion]) is kept in `PRAGMA user_version`.
class AppDatabase {
  AppDatabase._(this.db);

  /// Bump when the table layout below changes.
  static const schemaVersion = 1;

  final Database db;

  /// Opens (or creates) the DB at [path] and re-seeds it if the assets changed.
  /// Pass `':memory:'` in tests.
  static AppDatabase open(
    String path, {
    required String lawsJson,
    required String finesJson,
  }) {
    final db = sqlite3.open(path);
    final version = dataVersion(lawsJson, finesJson);
    final current = db.select('PRAGMA user_version').first.columnAt(0) as int;
    if (current != version) {
      _seed(db, lawsJson: lawsJson, finesJson: finesJson);
      db.execute('PRAGMA user_version = $version');
    }
    return AppDatabase._(db);
  }

  /// 31-bit FNV-1a over the asset text, so it fits `user_version` (int32 > 0).
  static int dataVersion(String lawsJson, String finesJson) {
    var hash = 0x811c9dc5;
    for (final unit in '$schemaVersion|$lawsJson|$finesJson'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return (hash & 0x7fffffff) | 1;
  }

  static void _seed(
    Database db, {
    required String lawsJson,
    required String finesJson,
  }) {
    db.execute('BEGIN');
    try {
      db.execute('''
        DROP TABLE IF EXISTS fines;
        DROP TABLE IF EXISTS fines_fts;
        DROP TABLE IF EXISTS laws;
        DROP TABLE IF EXISTS laws_fts;

        CREATE TABLE fines(
          id INTEGER PRIMARY KEY,
          violation TEXT NOT NULL,
          agency TEXT NOT NULL,
          amount REAL NOT NULL,
          legal_basis TEXT NOT NULL,
          aliases TEXT NOT NULL -- JSON array
        );
        CREATE VIRTUAL TABLE fines_fts USING fts5(
          violation, aliases,
          tokenize = 'unicode61 remove_diacritics 2', prefix = '2 3'
        );

        CREATE TABLE laws(
          id TEXT PRIMARY KEY,
          source TEXT NOT NULL,
          section TEXT NOT NULL,
          title TEXT NOT NULL,
          text TEXT NOT NULL,
          tags TEXT NOT NULL -- JSON array
        );
        CREATE VIRTUAL TABLE laws_fts USING fts5(
          title, text, tags,
          tokenize = 'unicode61 remove_diacritics 2', prefix = '2 3'
        );
      ''');

      final insertFine = db.prepare(
        'INSERT INTO fines(id, violation, agency, amount, legal_basis, aliases) '
        'VALUES (?, ?, ?, ?, ?, ?)',
      );
      final insertFineFts = db.prepare(
        'INSERT INTO fines_fts(rowid, violation, aliases) VALUES (?, ?, ?)',
      );
      var id = 0;
      for (final f in jsonDecode(finesJson) as List<dynamic>) {
        final m = f as Map<String, dynamic>;
        final aliases = (m['aliases'] as List<dynamic>? ?? const []).cast<String>();
        id++;
        insertFine.execute([
          id,
          m['violation'],
          (m['agency'] as String).toLowerCase(),
          m['amount'],
          m['legal_basis'],
          jsonEncode(aliases),
        ]);
        insertFineFts.execute([id, m['violation'], aliases.join(' ; ')]);
      }
      insertFine.close();
      insertFineFts.close();

      final insertLaw = db.prepare(
        'INSERT INTO laws(id, source, section, title, text, tags) '
        'VALUES (?, ?, ?, ?, ?, ?)',
      );
      final insertLawFts = db.prepare(
        'INSERT INTO laws_fts(rowid, title, text, tags) '
        'VALUES ((SELECT rowid FROM laws WHERE id = ?), ?, ?, ?)',
      );
      for (final l in jsonDecode(lawsJson) as List<dynamic>) {
        final m = l as Map<String, dynamic>;
        final tags = (m['tags'] as List<dynamic>? ?? const []).cast<String>();
        insertLaw.execute([
          m['id'],
          m['source'],
          m['section'],
          m['title'],
          m['text'],
          jsonEncode(tags),
        ]);
        insertLawFts.execute([m['id'], m['title'], m['text'], tags.join(' ')]);
      }
      insertLaw.close();
      insertLawFts.close();

      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => db.close();
}
