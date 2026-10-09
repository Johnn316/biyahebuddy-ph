import 'dart:io';

import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/hybrid_retriever.dart';
import 'package:biyahebuddy_ph/data/rag/law_retriever.dart';
import 'package:biyahebuddy_ph/data/rag/text_embedder.dart';
import 'package:biyahebuddy_ph/data/rag/vector_index.dart';

/// Builds the retrieval under test from command-line options.
///   --retriever fts      keyword-only FTS5 (the original app behaviour)
///   --retriever hybrid   FTS5 + embeddings (RRF) + intent + FAQ
///       --embedder models/embeddinggemma-300M-Q8_0.gguf
///       --embeddings assets/data/embeddings.json
class EvalSetup {
  EvalSetup._(this.keyword, this.hybrid, this.description, this._embedder);

  final LawRetriever keyword;
  final HybridRetriever? hybrid;
  final String description;
  final LlamaTextEmbedder? _embedder;

  static Future<EvalSetup> create(
    AppDatabase db,
    Map<String, String> opts,
  ) async {
    final keyword = LawRetriever(db);
    final kind = opts['retriever'] ?? 'fts';
    switch (kind) {
      case 'fts':
        return EvalSetup._(keyword, null, 'FTS5 keyword (baseline)', null);
      case 'hybrid':
        final index = VectorIndex.fromJson(
          File(
            opts['embeddings'] ?? 'assets/data/embeddings.json',
          ).readAsStringSync(),
        );
        final embedder = LlamaTextEmbedder(
          spec: EmbeddingSpec.byId(index.modelId),
          modelPath: () async =>
              opts['embedder'] ?? 'models/embeddinggemma-300M-Q8_0.gguf',
        );
        await embedder.load();
        return EvalSetup._(
          keyword,
          HybridRetriever(keyword: keyword, index: index, embedder: embedder),
          'Hybrid FTS5 + ${index.modelId} (RRF, intent, FAQ: '
          '${index.faq.length} phrasings)',
          embedder,
        );
      default:
        throw ArgumentError('Unknown --retriever $kind');
    }
  }

  Future<void> dispose() async => _embedder?.dispose();
}
