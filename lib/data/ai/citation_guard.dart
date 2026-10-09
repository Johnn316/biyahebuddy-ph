/// Keeps the LLM from citing a law section that wasn't retrieved.
///
/// The analysis streams through here sentence by sentence: a sentence is
/// held until it ends, then every "RA 1234 Sec. 5" in it that is NOT in
/// [allowed] is replaced with "ang batas sa itaas". Small models otherwise
/// copy citations from the prompt or make them up.
class CitationGuard {
  CitationGuard(Set<String> allowed)
    : allowed = {for (final id in allowed) _base(id)};

  /// Law ids like "ra4136-s44" (parts "-p2" are folded into the section).
  final Set<String> allowed;

  final _pending = StringBuffer();

  static final citation = RegExp(
    r'R\.?\s?A\.?\s*(?:No\.?\s*)?(\d{3,5}),?\s*(?:Sec(?:tion)?\.?|Seksyon)\s*(\d+)',
    caseSensitive: false,
  );

  // Sentence ends, but not "Sec. 41" / "No. 5" / "R.A.".
  static final _sentenceEnd = RegExp(
    r'(?<=[.!?])(?<!\bSec\.)(?<!\bNo\.)(?<!\bBlg\.)(?<!\bR\.A\.)(?<!\bR\.)\s+|\n',
    caseSensitive: false,
  );

  /// Cleaned text that is safe to show now (whole sentences only).
  String add(String text) {
    _pending.write(text);
    final s = '$_pending';
    final ends = _sentenceEnd.allMatches(s).toList();
    if (ends.isEmpty) return '';
    final cut = ends.last.end;
    _pending
      ..clear()
      ..write(s.substring(cut));
    return clean(s.substring(0, cut));
  }

  /// Whatever is still held (call when generation ends).
  String close() {
    final rest = '$_pending';
    _pending.clear();
    return clean(rest);
  }

  /// Replaces citations not in [allowed].
  String clean(String text) => text.replaceAllMapped(
    citation,
    (m) =>
        allowed.contains('ra${m[1]}-s${m[2]}') ? m[0]! : 'ang batas sa itaas',
  );

  static String _base(String id) => id.replaceFirst(RegExp(r'-p\d+$'), '');
}
