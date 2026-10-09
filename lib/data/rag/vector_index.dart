import 'dart:convert';
import 'dart:typed_data';

/// Precomputed embeddings (assets/data/embeddings.json, built on the PC by
/// tools/build_embeddings.dart). On the phone only the question is embedded;
/// documents are looked up here. Vectors are L2-normalized, so cosine
/// similarity is a dot product.
class VectorIndex {
  VectorIndex._({
    required this.modelId,
    required this.dims,
    required this.sourceHash,
    required this.laws,
    required this.fines,
    required this.faq,
    required this.fineLaws,
  });

  final String modelId;
  final int dims;

  /// Hash of laws.json + fines.json + faq.json the vectors were built from.
  final int sourceHash;

  /// Law id → vector.
  final Map<String, Float32List> laws;

  /// Index in fines.json (0-based) → vector.
  final List<Float32List> fines;

  /// fines.json index → law ids semantically closest to that fine
  /// (precomputed doc-to-doc), so MMDA/city fines link to the RA section.
  final List<List<String>> fineLaws;

  List<String> lawsForFine(int fineIndex) =>
      fineIndex >= 0 && fineIndex < fineLaws.length
      ? fineLaws[fineIndex]
      : const [];

  /// FAQ phrasings (question + aliases), each linked to law sections.
  final List<({String id, Float32List vec, List<String> sections, String text})>
  faq;

  static VectorIndex fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    Float32List vec(String b64) =>
        Uint8List.fromList(base64Decode(b64)).buffer.asFloat32List();
    return VectorIndex._(
      modelId: m['model'] as String,
      dims: m['dims'] as int,
      sourceHash: m['source_hash'] as int,
      laws: {
        for (final e in (m['laws'] as Map<String, dynamic>).entries)
          e.key: vec(e.value as String),
      },
      fines: [for (final v in m['fines'] as List<dynamic>) vec(v as String)],
      fineLaws: [
        for (final l in m['fine_laws'] as List<dynamic>? ?? const [])
          (l as List<dynamic>).cast<String>(),
      ],
      faq: [
        for (final f in m['faq'] as List<dynamic>? ?? const [])
          (
            id: (f as Map<String, dynamic>)['id'] as String? ?? '',
            vec: vec(f['vec'] as String),
            sections: (f['sections'] as List<dynamic>).cast<String>(),
            text: f['text'] as String,
          ),
      ],
    );
  }

  static String encode(List<double> v) =>
      base64Encode(Float32List.fromList(v).buffer.asUint8List());

  /// 31-bit FNV-1a over the source JSON (same idea as AppDatabase). Ignores
  /// '\r' so a CRLF checkout can't silently disable semantic retrieval.
  static int hashSources(String laws, String fines, String faq) {
    var hash = 0x811c9dc5;
    for (final unit in '$laws|$fines|$faq'.replaceAll('\r', '').codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  static double dot(List<double> a, Float32List b) {
    var s = 0.0;
    for (var i = 0; i < b.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  /// Law ids, best first.
  List<({String id, double score})> topLaws(List<double> q, int k) {
    final scored = [
      for (final e in laws.entries) (id: e.key, score: dot(q, e.value)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList(growable: false);
  }

  /// fines.json indexes (0-based), best first.
  List<({int index, double score})> topFines(List<double> q, int k) {
    final scored = [
      for (var i = 0; i < fines.length; i++)
        (index: i, score: dot(q, fines[i])),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList(growable: false);
  }

  /// Best FAQ phrasings, best first.
  List<({String id, List<String> sections, double score, String text})> topFaq(
    List<double> q,
    int k,
  ) {
    final scored = [
      for (final f in faq)
        (id: f.id, sections: f.sections, score: dot(q, f.vec), text: f.text),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList(growable: false);
  }
}
