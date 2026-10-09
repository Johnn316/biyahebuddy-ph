/// Turns free Taglish text into a safe FTS5 MATCH expression.
///
/// User text never reaches FTS5 syntax directly: only letter/digit words are
/// kept, each is quoted, filler words are dropped, and words are OR-ed with a
/// prefix match so "walang helmet" or "nag-beating the red light" still hit.
/// bm25 then ranks rows that match more words first.
/// Returns null when nothing searchable is left.
String? ftsQuery(String text, {bool allWords = false}) {
  final words = RegExp(r'[\p{L}\p{N}]+', unicode: true)
      .allMatches(text.toLowerCase())
      .map((m) => m.group(0)!)
      .where((w) => w.length >= 2 && !_stopwords.contains(w))
      .toSet();
  if (words.isEmpty) return null;
  // A word and its Tagalog root(s) are alternatives: ("nakaparada"* OR
  // "parada"*), so roots never become extra required words in AND mode.
  return words
      .map((w) {
        final roots = tagalogRoots(w);
        return roots.isEmpty
            ? '"$w"*'
            : '(${['"$w"*', for (final r in roots) '"$r"*'].join(' OR ')})';
      })
      .join(allWords ? ' AND ' : ' OR ');
}

/// Light Tagalog stemming so affixed forms meet their root:
/// "nakaparada"/"pumarada" → "parada", "nagmamaneho" → "maneho",
/// "nakainom" → "inom", "kumanan" → "kanan", "nabangga" → "bangga".
/// Strips one common prefix, an -um-/-in- infix, and a reduplicated first
/// syllable. Roots shorter than 4 letters are dropped (too ambiguous).
Set<String> tagalogRoots(String word) {
  var s = word;
  for (final p in _prefixes) {
    if (s.startsWith(p) && s.length - p.length >= 4) {
      s = s.substring(p.length);
      break;
    }
  }
  final infix = _infix.firstMatch(s);
  if (infix != null) s = '${infix[1]}${infix[3]}';
  final redup = _reduplication.firstMatch(s);
  if (redup != null) s = '${redup[1]}${redup[2]}';
  return s != word && s.length >= 4 ? {s} : const {};
}

/// Longest first, so "naka" wins over "na".
const _prefixes = [
  'nakikipag',
  'nakapag',
  'makapag',
  'pinaka',
  'nagpa',
  'magpa',
  'naka',
  'maka',
  'nag',
  'mag',
  'pag',
  'ipa',
  'na',
  'ma',
];

/// Consonant + "um"/"in" + vowel…: "pumarada" → "parada".
final _infix = RegExp(r'^([bcdfghjklmnpqrstvwyz])(um|in)([aeiou].{2,})$');

/// Repeated first (C)V syllable: "mamaneho" → "maneho", "tatawid" → "tawid".
final _reduplication = RegExp(r'^([bcdfghjklmnpqrstvwyz]?[aeiou])\1(.{3,})$');

/// Filler words that would match almost everything.
const _stopwords = {
  // Filipino
  'ang', 'ng', 'sa', 'na', 'ay', 'mga', 'ko', 'ako', 'ka', 'mo', 'ba', 'po',
  'yung', 'iyong', 'pag', 'kapag', 'kung', 'ano', 'magkano', 'multa', 'ito',
  'yan', 'siya', 'kami', 'tayo', 'nang', 'para', 'may', 'ni', 'si', 'din',
  'rin', 'lang', 'naman', 'dahil', 'kasi', 'ung', 'nag', 'ma', 'daw', 'raw',
  'sabi', 'gagawin', 'gawin', 'dapat', 'pwede', 'puwede', 'kailangan',
  'habang', 'akin', 'amin', 'namin', 'niya', 'nila', 'sila',
  // Generic "to drive": nearly every fine's aliases say "habang nagmamaneho",
  // so these drowned the word that matters ("kaskasero" → Reckless).
  'maneho', 'magmaneho', 'nagmamaneho', 'nagmaneho', 'pagmamaneho',
  'mamaneho', 'minamaneho', 'driving', 'drive', 'driver',
  // Negations: "walang helmet" must not match "walang lisensya".
  'wala', 'walang', 'hindi', 'di', 'no', 'not', 'without',
  // English
  'the', 'a', 'an', 'of', 'to', 'for', 'and', 'or', 'is', 'in', 'on', 'my',
  'fine', 'how', 'much', 'what', 'violation',
};
