import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/law_retriever.dart';
import 'package:flutter_test/flutter_test.dart';

String _law(String id, String source, String sec, String title, String text,
        [List<String> tags = const []]) =>
    '{"id":"$id","source":"$source","section":"$sec","title":"$title",'
    '"text":"$text","tags":[${tags.map((t) => '"$t"').join(',')}]}';

final _laws = '[${[
  _law('h1', 'RA 10054 (Helmet Act)', 'Sec. 1', 'Short Title',
      'This Act shall be known as the Motorcycle Helmet Act.', ['helmet']),
  _law('h3', 'RA 10054 (Helmet Act)', 'Sec. 3', 'Mandatory Use of Helmets',
      'All motorcycle riders shall wear helmets.', ['helmet']),
  _law('h7', 'RA 10054 (Helmet Act)', 'Sec. 7', 'Penalties',
      'Not wearing a helmet shall be punished with a fine.', ['helmet']),
  _law('c10', 'RA 11229 (Child Safety Act)', 'Sec. 10', 'Penalties',
      'Violators shall be fined for each child.', ['bata']),
  _law('s4', 'RA 8750 (Seat Belts Use Act)', 'Sec. 4',
      'Mandatory Use of Seat Belts', 'Drivers and passengers shall wear seat belts.'),
].join(',')}]';

void main() {
  late AppDatabase db;
  late LawRetriever retriever;
  setUp(() {
    db = AppDatabase.open(':memory:', lawsJson: _laws, finesJson: '[]');
    retriever = LawRetriever(db);
  });
  tearDown(() => db.close());

  List<String> ids(String q, {bool fine = false}) =>
      retriever.laws(q, aboutFine: fine).map((c) => c.id).toList();

  test('fine question: same-topic penalty first, no other law penalties', () {
    expect(ids('Magkano multa pag walang helmet?', fine: true), ['h7', 'h3']);
  });

  test('boilerplate sections (Short Title) are never returned', () {
    expect(ids('helmet'), isNot(contains('h1')));
  });

  test('Taglish synonym reaches the English law text', () {
    expect(ids('Walang seatbelt yung pasahero ko'), ['s4']);
  });

  test('filler-only question retrieves nothing', () {
    expect(ids('ano po?'), isEmpty);
  });
}
