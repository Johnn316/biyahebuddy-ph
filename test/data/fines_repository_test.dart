import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/local/fts_query.dart';
import 'package:biyahebuddy_ph/data/repositories/sqlite_fines_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _fines = '''
[
  {"violation": "Driving without a valid license", "agency": "lto", "amount": 3000,
   "legal_basis": "TEST", "aliases": ["walang lisensya", "no license"]},
  {"violation": "No helmet", "agency": "lto", "amount": 1500,
   "legal_basis": "TEST", "aliases": ["walang helmet", "helmet"]},
  {"violation": "Disregarding traffic signs", "agency": "mmda", "amount": 1000,
   "legal_basis": "TEST", "aliases": ["beating the red light", "swerving"]},
  {"violation": "Number coding (UVVRP) violation", "agency": "mmda", "amount": 300,
   "legal_basis": "TEST", "aliases": ["coding", "number coding"]}
]
''';

void main() {
  late AppDatabase database;
  late SqliteFinesRepository repo;

  setUp(() {
    database = AppDatabase.open(':memory:', lawsJson: '[]', finesJson: _fines);
    repo = SqliteFinesRepository(database);
  });
  tearDown(() => database.close());

  Future<List<String>> names(String q, Agency a) async =>
      (await repo.search(q, a)).map((f) => f.violation).toList();

  test('Taglish question finds the alias, not the other "walang" fine', () async {
    expect(await names('Magkano multa pag walang helmet?', Agency.lto), [
      'No helmet',
    ]);
  });

  test('filters by agency', () async {
    expect(await names('helmet', Agency.mmda), isEmpty);
    expect(await names('coding', Agency.mmda), [
      'Number coding (UVVRP) violation',
    ]);
  });

  test('enforcer phrase with mixed case and punctuation', () async {
    final hits = await names(
      'Na-flag ako ng MMDA dahil sa BEATING the red light!',
      Agency.mmda,
    );
    expect(hits.first, 'Disregarding traffic signs');
  });

  test('all-words matches beat single-word matches', () async {
    // "light" alone would also hit a "Light truck ban" row.
    final db2 = AppDatabase.open(':memory:', lawsJson: '[]', finesJson: '''[
      {"violation": "Light truck ban violation", "agency": "mmda", "amount": 2000,
       "legal_basis": "TEST", "aliases": ["truck ban"]},
      {"violation": "Disregarding traffic signs", "agency": "mmda", "amount": 1000,
       "legal_basis": "TEST", "aliases": ["beating the red light"]}
    ]''');
    addTearDown(db2.close);
    final hits = await SqliteFinesRepository(db2)
        .search('beating the red light', Agency.mmda);
    expect(hits.map((f) => f.violation), ['Disregarding traffic signs']);
  });

  test('falls back to any-word match when no row has every word', () async {
    expect(await names('helmet ng anak', Agency.lto), ['No helmet']);
  });

  test('prefix match on partial words', () async {
    expect(await names('lisens', Agency.lto), [
      'Driving without a valid license',
    ]);
  });

  test('empty or filler-only query lists the whole agency', () async {
    expect(await names('', Agency.lto), hasLength(2));
    expect(await names('magkano po?', Agency.lto), hasLength(2));
  });

  test('FTS syntax in user text cannot break the query', () async {
    const nasty = ['"', 'helmet"*', 'AND OR NOT', 'NEAR(', "x' --", '*', '-a'];
    for (final q in nasty) {
      await expectLater(repo.search(q, Agency.lto), completes, reason: q);
    }
  });

  test('maps all fields back', () async {
    final f = (await repo.search('helmet', Agency.lto)).single;
    expect(f.amount, 1500);
    expect(f.agency, Agency.lto);
    expect(f.legalBasis, 'TEST');
    expect(f.aliases, ['walang helmet', 'helmet']);
  });

  test('ftsQuery quotes words and drops filler', () {
    expect(ftsQuery('Magkano multa pag walang helmet?'), '"helmet"*');
    expect(ftsQuery('?? !!'), isNull);
  });
}
