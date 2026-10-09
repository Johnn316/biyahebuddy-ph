import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('bundled SQLite has FTS5 with bm25 ranking', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    db.execute('CREATE VIRTUAL TABLE t USING fts5(x)');
    db.execute("INSERT INTO t(x) VALUES ('walang helmet'), ('beating the red light')");

    final rows = db.select(
      "SELECT x FROM t WHERE t MATCH 'helmet' ORDER BY bm25(t)",
    );
    expect(rows.map((r) => r['x']), ['walang helmet']);
  });
}
