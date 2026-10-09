/// Cleans the LLM stream, which should hold only the "Pagsusuri" text
/// (code writes the other three sections).
///
/// - Drops a leading "Pagsusuri:" header the model may echo.
/// - Stops ([done]) when the model starts any other section, repeats a line,
///   or has written [maxSentences]: small models loop otherwise, and stopping
///   early also saves time on the phone.
/// - Streams text as it comes; only holds back the start of a line while it
///   could still turn out to be a header.
class SectionFilter {
  SectionFilter({this.maxSentences = 4});

  final int maxSentences;

  static const _names = [
    'kalma muna',
    'ano ang sinasabi ng batas',
    'batas',
    'pagsusuri',
    'ano ang gagawin',
    'gagawin',
  ];

  static final _header = RegExp(
    r'^\s*(#{1,6}\s*)?(\*\*)?\s*(kalma\s+muna|ano\s+ang\s+sinasabi\s+ng\s+batas'
    r'|batas|pagsusuri|ano\s+ang\s+gagawin|gagawin)\s*([:.])?\s*(\*\*)?\s*([:.])?'
    r'\s*(.*)$',
    caseSensitive: false,
  );

  String _line = '';
  bool _lineOpen = false;
  bool _done = false;
  bool _wroteText = false;
  int _sentences = 0;
  final _seenLines = <String>{};
  final _openLine = StringBuffer();

  /// True once the analysis is complete; stop generating.
  bool get done => _done;

  /// Text to append to the answer for this model [chunk].
  String add(String chunk) {
    final out = StringBuffer();
    final parts = chunk.split('\n');
    for (var i = 0; i < parts.length && !_done; i++) {
      final seg = parts[i];
      final endsLine = i < parts.length - 1;
      if (_lineOpen) {
        _emit(out, seg);
        if (endsLine) _endOpenLine(out);
        continue;
      }
      _line += seg;
      if (endsLine) {
        _finishLine(out);
      } else if (_line.isNotEmpty &&
          !_mayBeHeader(_line) &&
          !_mayRepeat(_line)) {
        _lineOpen = true;
        final text = _line;
        _line = '';
        _emit(out, text);
      }
    }
    return '$out';
  }

  /// Flushes the last line; returns [fallback] if the model wrote nothing.
  String close({required String fallback}) {
    final out = StringBuffer();
    if (!_done) {
      if (_lineOpen) {
        _endOpenLine(out);
      } else if (_line.isNotEmpty) {
        _finishLine(out);
      }
    }
    if (!_wroteText) out.write(fallback);
    return '$out';
  }

  void _emit(StringBuffer out, String text) {
    if (_done || text.isEmpty) return;
    var cut = text.length;
    for (var i = 0; i < text.length; i++) {
      if (_endsSentence(text, i) && ++_sentences >= maxSentences) {
        cut = i + 1;
        _done = true;
        break;
      }
    }
    final kept = text.substring(0, cut);
    _tail = '$_tail$kept';
    if (_tail.length > 12) _tail = _tail.substring(_tail.length - 12);
    if (_lineOpen) _openLine.write(kept);
    if (kept.trim().isNotEmpty) _wroteText = true;
    out.write(kept);
    if (_done) out.write('\n');
  }

  void _endOpenLine(StringBuffer out) {
    _lineOpen = false;
    final line = _openLine.toString().trim().toLowerCase();
    _openLine.clear();
    if (line.isNotEmpty && !_seenLines.add(line)) _done = true;
    if (!_done) out.write('\n');
  }

  void _finishLine(StringBuffer out) {
    final line = _line;
    _line = '';
    final m = _header.firstMatch(line);
    final isHeader = m != null &&
        (m.group(1) != null ||
            m.group(2) != null ||
            m.group(4) != null ||
            m.group(6) != null ||
            (m.group(7) ?? '').isEmpty);
    if (isHeader) {
      if (!m.group(3)!.toLowerCase().startsWith('pagsusuri')) {
        _done = true; // The model moved on to another section.
        return;
      }
      final rest = (m.group(7) ?? '').replaceAll('**', '').trim();
      if (rest.isEmpty) return;
      _seenLines.add(rest.toLowerCase());
      _emit(out, rest);
      if (!_done) out.write('\n');
      return;
    }
    if (line.trim().isEmpty) {
      if (_wroteText) out.write('\n');
      return;
    }
    if (!_seenLines.add(line.trim().toLowerCase())) {
      _done = true; // Repeating itself.
      return;
    }
    _emit(out, line.replaceAll('**', ''));
    if (!_done) out.write('\n');
  }

  /// Last few emitted characters, to see the word before a period that
  /// arrives in a later chunk.
  String _tail = '';

  static final _abbrev = RegExp(
    r'(?:^|[^\p{L}])(sec|no|blg|art|hal|php|rep|par|st|gen)$',
    caseSensitive: false,
    unicode: true,
  );

  /// "." "!" "?" ends a sentence, except in "Sec. 41", "No. 5", "1,500.00".
  bool _endsSentence(String text, int i) {
    final c = text[i];
    if (c == '!' || c == '?') return true;
    if (c != '.') return false;
    final before = '$_tail${text.substring(0, i)}';
    if (before.isEmpty) return false;
    if (RegExp(r'\d$').hasMatch(before)) return false;
    return !_abbrev.hasMatch(before);
  }

  /// Hold a line back while it could still be a copy of an earlier one.
  bool _mayRepeat(String partial) {
    final p = partial.trim().toLowerCase();
    return _seenLines.any((l) => l.startsWith(p));
  }

  static bool _mayBeHeader(String partial) {
    final n = partial
        .toLowerCase()
        .replaceFirst(RegExp(r'^[\s#*]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return true;
    return _names.any((w) => w.startsWith(n) || n.startsWith(w));
  }
}
