import 'package:flutter_test/flutter_test.dart';

import '../../tools/eval/answer_quality.dart';

String answer({
  String batas = '• RA 10054 Sec. 7 — Penalties\n'
      '  "fine of One thousand five hundred pesos (Php1,500.00)"\n'
      '• Multa (LTO): ₱1,500 — No / non-standard motorcycle helmet\n',
  String pagsusuri = 'May multa na ₱1,500 sa unang huli.',
}) =>
    '**Kalma muna**\nKalma lang.\n\n'
    '**Ano ang sinasabi ng batas**\n$batas\n'
    '**Pagsusuri**\n$pagsusuri\n\n'
    '**Ano ang gagawin**\n1. Magsuot ng helmet.\n';

void main() {
  List<String> check(String full) =>
      answerProblems(full, expLaws: ['ra10054-s7'], expFines: ['helmet']);

  test('a good answer has no problems', () {
    expect(check(answer()), isEmpty);
  });

  test('missing or repeated header is a format problem', () {
    expect(check(answer().replaceFirst('**Pagsusuri**\n', '')), [
      startsWith('format'),
    ]);
  });

  test('blame is flagged, the code-written neutral frame is not', () {
    expect(
      check(answer(pagsusuri: 'Hindi ito pinal na hatol kung sino ang may sala.')),
      isEmpty,
    );
    expect(check(answer(pagsusuri: 'May kasalanan si Driver A.')), [
      startsWith('blame'),
    ]);
  });

  test('wrong law or fine shown is flagged', () {
    final problems = check(
      answer(batas: '• RA 4136 Sec. 35 — Speed\n• Multa (LTO): ₱500 — Overspeeding\n'),
    );
    expect(problems, contains(startsWith('shown law')));
    expect(problems, contains(startsWith('shown fine')));
  });

  test('an amount the law/fines do not show is flagged', () {
    expect(check(answer(pagsusuri: 'Multa ay ₱2,000.')), [startsWith('amount')]);
    expect(check(answer(pagsusuri: 'Multa ay Php1,500.00.')), isEmpty);
  });
}
