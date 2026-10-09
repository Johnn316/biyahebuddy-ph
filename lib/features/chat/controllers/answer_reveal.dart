import 'answer_format.dart';

/// Words revealed per second while Buddy "types" (docs/DESIGN.md motion).
const revealWordsPerSecond = 38.0;

/// Typing dots stay at least this long, even if the answer is ready at once.
const minTypingDots = Duration(milliseconds: 600);

/// Splits an answer into reveal units whose concatenation is a prefix of
/// [text]: one word (with its trailing whitespace) per unit, but a section
/// header line and a law citation are each ONE unit, so a half-typed
/// "**Ano ang" or "RA 4136" never flashes on screen.
///
/// While [streaming], a last line that looks like an unfinished header
/// (`**…` / `#…` without a newline yet) is held back.
List<String> revealUnits(String text, {bool streaming = false}) {
  final units = <String>[];
  void add(String u) {
    if (u.trim().isEmpty && units.isNotEmpty) {
      units[units.length - 1] += u; // whitespace rides on the previous word
    } else {
      units.add(u);
    }
  }

  final lines = RegExp(r'[^\n]*\n|[^\n]+$').allMatches(text);
  for (final m in lines) {
    final line = m[0]!;
    final complete = line.endsWith('\n');
    final head = line.trimLeft();
    if (!complete &&
        streaming &&
        (head.startsWith('*') || head.startsWith('#'))) {
      break; // header (or bold text) still arriving
    }
    final parsed = parseAnswer(line);
    if (parsed.hasSections &&
        parsed.intro.isEmpty &&
        parsed.sections.single.body.isEmpty) {
      add(line);
      continue;
    }
    var pos = 0;
    void words(String s) {
      for (final w in RegExp(r'\S+\s*|\s+').allMatches(s)) {
        add(w[0]!);
      }
    }

    for (final c in citationPattern.allMatches(line)) {
      words(line.substring(pos, c.start));
      final ws = RegExp(r'\s*').matchAsPrefix(line, c.end)!;
      add(line.substring(c.start, ws.end));
      pos = ws.end;
    }
    words(line.substring(pos));
  }
  return units;
}
