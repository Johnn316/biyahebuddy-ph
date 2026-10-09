/// Parses Buddy's answer into the 4 labeled sections. Accepts the long and
/// short header names, with or without markdown (`**Batas:**`, `## Pagsusuri`).
library;

enum AnswerSectionKind {
  kalma('Kalma muna'),
  batas('Ano ang sinasabi ng batas'),
  pagsusuri('Pagsusuri'),
  gagawin('Ano ang gagawin');

  const AnswerSectionKind(this.label);

  final String label;
}

class AnswerSection {
  const AnswerSection(this.kind, this.body);

  final AnswerSectionKind kind;
  final String body;
}

class ParsedAnswer {
  const ParsedAnswer({required this.intro, required this.sections});

  /// Text before the first header (or the whole answer if there are none).
  final String intro;
  final List<AnswerSection> sections;

  bool get hasSections => sections.isNotEmpty;
}

const _headerNames = {
  AnswerSectionKind.kalma: r'kalma\s+muna',
  AnswerSectionKind.batas: r'(?:ano\s+ang\s+sinasabi\s+ng\s+)?batas',
  AnswerSectionKind.pagsusuri: r'pagsusuri',
  AnswerSectionKind.gagawin: r'(?:ano\s+ang\s+)?gagawin(?:\s+ngayon)?',
};

/// A line is a header only if the name is marked up (`**`, `#`) or followed
/// by `:` / `.` / end of line — so body text like "Batas ang…" isn't one.
final _headers = {
  for (final e in _headerNames.entries)
    e.key: RegExp(
      r'^\s*(#{1,6}\s*)?(\*\*)?\s*(' +
          e.value +
          r')\s*([:.])?\s*(\*\*)?\s*([:.])?\s*(.*)$',
      caseSensitive: false,
    ),
};

ParsedAnswer parseAnswer(String text) {
  final intro = StringBuffer();
  final sections = <(AnswerSectionKind, StringBuffer)>[];

  for (final line in text.split('\n')) {
    final header = _matchHeader(line);
    if (header != null) {
      sections.add((header.$1, StringBuffer(header.$2)));
      continue;
    }
    final target = sections.isEmpty ? intro : sections.last.$2;
    if (target.isNotEmpty) target.write('\n');
    target.write(line);
  }

  return ParsedAnswer(
    intro: _clean(intro.toString()),
    sections: [for (final (k, b) in sections) AnswerSection(k, _clean('$b'))],
  );
}

(AnswerSectionKind, String)? _matchHeader(String line) {
  for (final MapEntry(key: kind, value: re) in _headers.entries) {
    final m = re.firstMatch(line);
    if (m == null) continue;
    final markedUp = m.group(1) != null || m.group(2) != null;
    final punctuated = m.group(4) != null || m.group(6) != null;
    final rest = m.group(7) ?? '';
    if (markedUp || punctuated || rest.isEmpty) return (kind, rest);
  }
  return null;
}

/// Strips markdown bold markers and surrounding blank lines.
String _clean(String s) => s.replaceAll('**', '').trim();

/// Legal citations to highlight, e.g. "RA 4136 Sec. 42", "R.A. No. 10913",
/// "LTO JAO 2014-01", "MMDA Reg. 96-005", "PD 1605".
final citationPattern = RegExp(
  r'\b(?:'
  r'(?:R\.?\s?A\.?|Republic\s+Act)\s*(?:No\.?\s*)?\d{3,5}'
  r'(?:,?\s*(?:Sec\.?|Section)\s*\d+[A-Za-z]?(?:\s*\([a-z0-9]\))?)?'
  r'|(?:LTO\s+)?JAO\s+(?:No\.?\s*)?\d{4}-\d+'
  r'|MMDA\s+(?:Reg\.?|Regulation|MC|Memorandum\s+Circular)\s*(?:No\.?\s*)?[\d-]+'
  r'|(?:P\.?\s?D\.?|E\.?\s?O\.?|B\.?\s?P\.?)\s*(?:No\.?\s*)?\d{2,5}'
  r')',
  caseSensitive: false,
);
