import 'package:biyahebuddy_ph/data/ai/citation_guard.dart';
import 'package:biyahebuddy_ph/data/ai/local_ai_assistant.dart';
import 'package:biyahebuddy_ph/data/ai/local_llm.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/law_retriever.dart';
import 'package:flutter_test/flutter_test.dart';

const _laws = '''
[{"id": "ra8750-s4", "source": "RA 8750 (Seat Belts Use Act of 1999)",
  "section": "Sec. 4", "title": "Mandatory Use of Seat Belts",
  "text": "Drivers and front seat passengers shall wear seat belts.",
  "tags": ["seatbelt"]}]
''';

/// Streams [reply] in 5-character pieces, like a real model.
class _Scripted implements TextGenerator {
  _Scripted(this.reply);

  final String reply;

  @override
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 0,
  }) async* {
    for (var i = 0; i < reply.length; i += 5) {
      yield reply.substring(i, (i + 5).clamp(0, reply.length));
    }
  }
}

void main() {
  test('keeps retrieved citations, replaces invented ones', () {
    final g = CitationGuard({'ra8750-s4', 'ra4136-s34-p2'});
    expect(
      g.clean('Ayon sa RA 8750 Sec. 4, dapat naka-seatbelt.'),
      'Ayon sa RA 8750 Sec. 4, dapat naka-seatbelt.',
    );
    expect(
      g.clean('Ayon sa RA 8750 Sec. 44, bawal.'),
      'Ayon sa ang batas sa itaas, bawal.',
    );
    expect(
      g.clean('Tingnan ang R.A. 4136, Section 34.'),
      'Tingnan ang R.A. 4136, Section 34.',
    );
  });

  test('a citation split across stream chunks is still checked', () {
    final g = CitationGuard({'ra8750-s4'});
    final out = StringBuffer()
      ..write(g.add('Sabi ng RA 87'))
      ..write(g.add('50 Sec. 4'))
      ..write(g.add('4 na bawal ito. Ingat '))
      ..write(g.add('lagi.'))
      ..write(g.close());
    expect('$out', 'Sabi ng ang batas sa itaas na bawal ito. Ingat lagi.');
  });

  test('"Sec." is not a sentence end', () {
    final g = CitationGuard({'ra8750-s4'});
    expect(g.add('Ayon sa RA 8750 Sec. '), '');
    expect(g.add('4 dapat. '), 'Ayon sa RA 8750 Sec. 4 dapat. ');
  });

  test('assistant never shows a citation that was not retrieved', () async {
    final db = AppDatabase.open(':memory:', lawsJson: _laws, finesJson: '[]');
    addTearDown(db.close);
    final assistant = LocalAiAssistant(
      retriever: LawRetriever(db),
      llm: _Scripted(
        'Ayon sa RA 8750 Sec. 44, kailangan ng seatbelt. '
        'Tama rin ang RA 8750 Sec. 4.',
      ),
      isModelReady: () => true,
    );
    final answer = await assistant.ask('Kailangan ba ng seatbelt?').join();
    expect(answer, isNot(contains('Sec. 44')));
    expect(answer, contains('RA 8750 Sec. 4'));
    expect(answer, contains('ang batas sa itaas'));
  });
}
