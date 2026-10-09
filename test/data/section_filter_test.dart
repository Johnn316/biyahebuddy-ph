import 'package:biyahebuddy_ph/data/ai/section_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds [text] in small pieces like a token stream, the way the assistant
/// does (stops once the filter is done), and returns the output.
String run(String text, {int piece = 3, int maxSentences = 4}) {
  final f = SectionFilter(maxSentences: maxSentences);
  final out = StringBuffer();
  for (var i = 0; i < text.length && !f.done; i += piece) {
    out.write(f.add(text.substring(i, (i + piece).clamp(0, text.length))));
  }
  out.write(f.close(fallback: 'FALLBACK\n'));
  return '$out';
}

void main() {
  test('echoed Pagsusuri header is dropped, text kept', () {
    final out = run('Pagsusuri:\nMali ang hindi pag-signal.');
    expect(out, 'Mali ang hindi pag-signal.\n');
  });

  test('inline markdown header keeps its text', () {
    expect(run('**Pagsusuri:** Tama ka.'), 'Tama ka.\n');
  });

  test('stops when the model starts another section', () {
    final out = run(
      'Bawal ito ayon sa RA 4136 Sec. 41.\nGagawin:\n1. Huwag mag-overtake.',
    );
    expect(out, 'Bawal ito ayon sa RA 4136 Sec. 41.\n');
  });

  test('a model-invented law section is never shown', () {
    final out = run('Ano ang sinasabi ng batas:\nRA 9999 Sec. 1 imbento.');
    expect(out, isNot(contains('RA 9999')));
    expect(out, 'FALLBACK\n');
  });

  test('stops at a repeated line (1B models loop)', () {
    final out = run('Isang linya.\nIbang linya.\nIsang linya.\nIsang linya.\n');
    expect(out, 'Isang linya.\nIbang linya.\n');
  });

  test('stops after maxSentences', () {
    final out = run('Una. Pangalawa. Pangatlo. Pang-apat.', maxSentences: 2);
    expect(out, 'Una. Pangalawa.\n');
  });

  test('"Sec." and amounts do not count as sentence ends', () {
    final out = run(
      'Ayon sa RA 4136 Sec. 41, bawal ito. Multa Php1,500.00 ito. Huli.',
      maxSentences: 2,
    );
    expect(out, 'Ayon sa RA 4136 Sec. 41, bawal ito. Multa Php1,500.00 ito.\n');
  });

  test('empty model output gives the fallback', () {
    expect(run(''), 'FALLBACK\n');
  });

  test('body text starting with a header word is not a header', () {
    final out = run('Batas ang nagsasabi na bawal ito.');
    expect(out, 'Batas ang nagsasabi na bawal ito.\n');
  });

  test('streams long lines before the newline arrives', () {
    final f = SectionFilter();
    expect(f.add('Mabilis ang kabilang sasakyan'), 'Mabilis ang kabilang sasakyan');
    expect(f.add(' kanina\nPagsu'), ' kanina\n'); // "Pagsu…" might be a header
  });
}
