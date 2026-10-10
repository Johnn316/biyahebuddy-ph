import '../../../core/contracts/contracts.dart';

/// Guided "na-flag ako" flow in Buddy: code-driven, no LLM guessing.
/// 1) flagged but no violation named → ask which one (chips),
/// 2) match the answer with the Na-flag fine search, 3) show the fine card.

const flagQuestion = "Ano ang sinabing violation sa'yo?";
const flagQuestionHint = 'Pumili sa ibaba o i-type ito.';
const flagNoMatch = 'Hindi ko makita ang violation na iyan.';

/// What step a Buddy message is in the flow.
enum FlagStep { askViolation, noMatch, fine }

const _flaggedWords = [
  'na-flag',
  'naflag',
  'flag',
  'na flag',
  'pinara',
  'pinahinto',
  'hinuli',
  'nahuli',
  'huli ako',
  'pulled over',
  'stopped by',
];

/// Words that say nothing about WHICH violation.
const _filler = {
  'na-flag',
  'naflag',
  'flag',
  'flagged',
  'na',
  'pinara',
  'pinahinto',
  'hinuli',
  'nahuli',
  'huli',
  'ako',
  'ko',
  'mo',
  'ka',
  'ng',
  'ni',
  'sa',
  'ang',
  'ano',
  'anong',
  'dapat',
  'gawin',
  'gagawin',
  'ba',
  'po',
  'yung',
  'ung',
  'lang',
  'kasi',
  'eh',
  'naman',
  'ngayon',
  'kanina',
  'enforcer',
  'traffic',
  'mmda',
  'lto',
  'city',
  'hpg',
  'pulis',
  'ako?',
  'paano',
  'what',
  'should',
  'do',
  'i',
  'was',
  'got',
  'by',
  'the',
  'an',
  'a',
  'pulled',
  'over',
  'stopped',
  'me',
  'now',
  'help',
  'tulong',
  'kailangan',
  'gusto',
  'kong',
  'malaman',
  'aide',
  'officer',
  'ticket',
  'tiket',
  'tinikitan',
  'tiniketan',
  'at',
  'tapos',
  'pa',
  'din',
  'rin',
  'nga',
  'lungsod',
  'munisipyo',
  'barangay',
  'tanod',
};

/// Flagged by an enforcer, but no violation named (only filler words).
bool isFlaggedWithoutViolation(String question) {
  final q = question.toLowerCase();
  if (!_flaggedWords.any(q.contains)) return false;
  final rest = q
      .replaceAll(RegExp(r'[^a-z0-9ñ\s-]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1 && !_filler.contains(w));
  return rest.isEmpty;
}

/// Agency named in [text]; MMDA when none.
Agency detectAgency(String text) {
  final t = text.toLowerCase();
  if (RegExp(r'\blto\b').hasMatch(t)) return Agency.lto;
  if (RegExp(r'\bmmda\b').hasMatch(t)) return Agency.mmda;
  if (RegExp(
    r'\b(city|lungsod|munisipyo|barangay|tanod|qc|quezon|makati|manila|'
    r'pasig|taguig|cebu|davao)\b',
  ).hasMatch(t)) {
    return Agency.city;
  }
  return Agency.mmda;
}

/// Short chip label: "Disregarding traffic signs (incl. …) — 1st offense"
/// → "Disregarding traffic signs".
String violationLabel(Fine f) =>
    f.violation.split(' — ').first.split(' (').first.trim();

/// The [n] most common violations of an agency (fines.json order, offense
/// levels counted once).
List<String> commonViolations(List<Fine> fines, {int n = 6}) =>
    {for (final f in fines) violationLabel(f)}.take(n).toList();

/// Steps when stopped by an enforcer.
const flagSteps = [
  'Manatiling kalmado at magalang; ipakita ang lisensya at OR/CR.',
  'Humingi ng official ticket o TOP (Temporary Operator\'s Permit).',
  'Huwag magbayad on the spot nang walang opisyal na resibo.',
  'Kung hindi ka sang-ayon, i-contest ang ticket sa opisinang nakasulat '
      'dito (LTO, MMDA, o city hall) bago ang deadline.',
];
