import 'dart:async';

import 'package:llamadart/llamadart.dart';

/// How a multilingual embedding model expects queries and documents to be
/// phrased. Using the wrong prompt costs a lot of retrieval accuracy.
class EmbeddingSpec {
  const EmbeddingSpec({
    required this.id,
    required this.queryPrefix,
    required this.docFormat,
    this.maxDocChars = 1200,
  });

  /// Stored in the embeddings asset; query and documents must match.
  final String id;
  final String queryPrefix;

  /// `{title}` and `{text}` are replaced.
  final String docFormat;

  /// Keeps documents inside the model's context.
  final int maxDocChars;

  String query(String q) => '$queryPrefix$q';

  String doc(String title, String text) {
    final t = text.length > maxDocChars ? text.substring(0, maxDocChars) : text;
    return docFormat.replaceAll('{title}', title).replaceAll('{text}', t);
  }

  /// EmbeddingGemma 300M (Google, Gemma terms). 768 dims, 100+ languages.
  static const embeddingGemma = EmbeddingSpec(
    id: 'embeddinggemma-300m-q8',
    queryPrefix: 'task: search result | query: ',
    docFormat: 'title: {title} | text: {text}',
  );

  /// multilingual-e5-small (MIT). 384 dims, max 512 tokens.
  static const e5Small = EmbeddingSpec(
    id: 'multilingual-e5-small-q8',
    queryPrefix: 'query: ',
    docFormat: 'passage: {title}. {text}',
    maxDocChars: 900,
  );

  static const all = [embeddingGemma, e5Small];

  static EmbeddingSpec byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => throw ArgumentError(id));
}

/// Turns text into an L2-normalized vector.
abstract interface class TextEmbedder {
  EmbeddingSpec get spec;
  Future<List<double>> embed(String text);
}

/// llama.cpp (llamadart) running a local embedding GGUF on the CPU. Never
/// downloads: [modelPath] must point to a file LocalModelManager fetched.
/// Loads lazily; calls are queued one at a time.
class LlamaTextEmbedder implements TextEmbedder {
  LlamaTextEmbedder({required this.spec, required this.modelPath});

  @override
  final EmbeddingSpec spec;
  final Future<String> Function() modelPath;

  LlamaEngine? _engine;
  Future<LlamaEngine>? _loading;
  Future<void> _tail = Future.value();

  Future<void> load() => _ensureLoaded();

  Future<LlamaEngine> _ensureLoaded() async {
    if (_engine != null) return _engine!;
    _loading ??= () async {
      try {
        return _engine = await LlamaEngine.load(
          LlamaModel(ModelSource.path(await modelPath())),
          params: const ModelParams(
            contextSize: 1024,
            device: ComputeDevice.cpu,
          ),
        );
      } finally {
        _loading = null;
      }
    }();
    return _loading!;
  }

  @override
  Future<List<double>> embed(String text) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      await previous;
      final engine = await _ensureLoaded();
      return await engine.embed(text);
    } finally {
      done.complete();
    }
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
  }
}
