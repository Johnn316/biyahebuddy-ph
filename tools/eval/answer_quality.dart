// Answer-quality checks for the eval harness, run on the full answer text
// the user sees (after the citation guard and fault filter).
//
// An answer is OK when:
//   format — the 4 headers each appear once, on their own line, in order
//   blame  — no sentence assigns fault ("may kasalanan", "nagkamali", …),
//            apart from the code-written neutral frame
//   shown  — the "Ano ang sinasabi ng batas" section shows at least one
//            expected law citation and at least one expected fine
// ("invented citation" is checked in run_eval.dart with the guard's rules.)

const answerHeaders = [
  '**Kalma muna**',
  '**Ano ang sinasabi ng batas**',
  '**Pagsusuri**',
  '**Ano ang gagawin**',
];

/// Code-written sentences that mention fault only to deny it.
const _neutralSentences = [
  'Hindi ito pinal na hatol kung sino ang may sala.',
  'Ang pulis o korte ang magpapasya kung sino ang may pananagutan.',
];

final _blame = RegExp(
  r'kasalanan|may\s+sala|nagkamali|nagkakamali|mali\s+(?:si|ang)|may\s+mali'
  r'|at\s+fault|guilty|liable|dapat\s+sisihin|siya\s+ang\s+mali',
  caseSensitive: false,
);

final _citation = RegExp(
  r'R\.?\s?A\.?\s*(?:No\.?\s*)?(\d{3,5}),?\s*(?:Sec(?:tion)?\.?|Seksyon)\s*(\d+)',
  caseSensitive: false,
);

/// Problems found in [full] (empty = OK). [expLaws] are ids like
/// "ra4136-s42"; [expFines] are keywords of the expected fine's violation.
List<String> answerProblems(
  String full, {
  required List<String> expLaws,
  required List<String> expFines,
}) {
  final problems = <String>[];
  final lines = full.split('\n').map((l) => l.trim()).toList();

  // format
  final positions = [for (final h in answerHeaders) lines.indexOf(h)];
  final counts = [
    for (final h in answerHeaders) lines.where((l) => l == h).length,
  ];
  if (positions.contains(-1) || counts.any((c) => c != 1)) {
    problems.add('format: headers missing or repeated');
  } else {
    for (var i = 1; i < positions.length; i++) {
      if (positions[i] < positions[i - 1]) {
        problems.add('format: headers out of order');
        break;
      }
    }
  }

  // blame
  var text = full;
  for (final s in _neutralSentences) {
    text = text.replaceAll(s, '');
  }
  final blamed = _blame.firstMatch(text);
  if (blamed != null) problems.add('blame: "${blamed[0]}"');

  // shown law / fine (only in the Batas section, which code writes)
  final start = full.indexOf(answerHeaders[1]);
  final end = full.indexOf(answerHeaders[2]);
  final batas = start < 0
      ? ''
      : full.substring(start, end < start ? full.length : end);
  if (expLaws.isNotEmpty) {
    final shown = {
      for (final m in _citation.allMatches(batas)) 'ra${m[1]}-s${m[2]}',
    };
    if (!expLaws.any(shown.contains)) {
      problems.add('shown law: none of ${expLaws.join('/')}');
    }
  }
  if (expFines.isNotEmpty) {
    final lower = batas.toLowerCase();
    final fineLines = lower.split('\n').where((l) => l.contains('multa ('));
    if (!expFines.any((f) => fineLines.any((l) => l.contains(f.toLowerCase())))) {
      problems.add('shown fine: none of ${expFines.join('/')}');
    }
  }
  // amounts: every peso amount the LLM wrote must appear in the Batas
  // section (verbatim law text or a shown fine).
  final pStart = full.indexOf(answerHeaders[2]);
  final pEnd = full.indexOf(answerHeaders[3]);
  if (pStart >= 0) {
    final analysis = full.substring(pStart, pEnd < pStart ? full.length : pEnd);
    final shownAmounts = {
      for (final m in _amount.allMatches(batas)) _digits(m[1]!),
    };
    for (final m in _amount.allMatches(analysis)) {
      if (!shownAmounts.contains(_digits(m[1]!))) {
        problems.add('amount: ${m[0]} not in the shown law/fines');
        break;
      }
    }
  }
  return problems;
}

final _amount = RegExp(
  r'(?:₱|Php|PHP|P)\s?(\d{1,3}(?:,\d{3})+|\d{3,})',
  caseSensitive: false,
);

/// "1,500.00" / "1500" → "1500".
String _digits(String s) => s.replaceAll(',', '');
