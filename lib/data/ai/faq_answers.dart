import 'dart:convert';

/// One curated answer from `assets/data/faq.json`: written and checked by
/// hand against laws.json, so common questions don't depend on the 1B model.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.aliases,
    required this.sections,
    required this.pagsusuri,
    required this.gagawin,
  });

  factory FaqEntry.fromJson(Map<String, dynamic> m) => FaqEntry(
    id: m['id'] as String,
    question: m['question'] as String,
    aliases: (m['aliases'] as List<dynamic>? ?? const []).cast<String>(),
    sections: (m['sections'] as List<dynamic>? ?? const []).cast<String>(),
    pagsusuri: m['pagsusuri'] as String? ?? '',
    gagawin: (m['gagawin'] as List<dynamic>? ?? const []).cast<String>(),
  );

  final String id;
  final String question;
  final List<String> aliases;

  /// Law section ids (laws.json) that truly apply.
  final List<String> sections;
  final String pagsusuri;
  final List<String> gagawin;

  /// Usable as a curated answer (older faq.json entries only link sections).
  bool get curated => pagsusuri.isNotEmpty && gagawin.isNotEmpty;

  List<String> get phrasings => [question, ...aliases];

  static List<FaqEntry> parse(String json) {
    try {
      return [
        for (final m in (jsonDecode(json) as List<dynamic>))
          FaqEntry.fromJson(m as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }
}

/// Keyword-only FAQ match (no embedding model): word overlap with a
/// phrasing. Strict on purpose — a wrong curated answer is worse than none.
({FaqEntry entry, double score})? lexicalFaqMatch(
  String question,
  List<FaqEntry> faq,
) {
  final q = _words(question);
  if (q.length < 3) return null;
  ({FaqEntry entry, double score})? best;
  for (final e in faq) {
    for (final p in e.phrasings) {
      final w = _words(p);
      final inter = q.intersection(w).length;
      final union = q.union(w).length;
      final score = union == 0 ? 0.0 : inter / union;
      if (best == null || score > best.score) best = (entry: e, score: score);
    }
  }
  return best;
}

Set<String> _words(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9ñ\s-]'), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 1)
    .toSet();
