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
  return words.map((w) => '"$w"*').join(allWords ? ' AND ' : ' OR ');
}

/// Filler words that would match almost everything.
const _stopwords = {
  // Filipino
  'ang', 'ng', 'sa', 'na', 'ay', 'mga', 'ko', 'ako', 'ka', 'mo', 'ba', 'po',
  'yung', 'iyong', 'pag', 'kapag', 'kung', 'ano', 'magkano', 'multa', 'ito',
  'yan', 'siya', 'kami', 'tayo', 'nang', 'para', 'may', 'ni', 'si', 'din',
  'rin', 'lang', 'naman', 'dahil', 'kasi', 'ung', 'nag', 'ma', 'daw', 'raw',
  'sabi', 'gagawin', 'gawin', 'dapat', 'pwede', 'puwede', 'kailangan',
  'habang', 'akin', 'amin', 'namin', 'niya', 'nila', 'sila',
  // Negations: "walang helmet" must not match "walang lisensya".
  'wala', 'walang', 'hindi', 'di', 'no', 'not', 'without',
  // English
  'the', 'a', 'an', 'of', 'to', 'for', 'and', 'or', 'is', 'in', 'on', 'my',
  'fine', 'how', 'much', 'what', 'violation',
};
