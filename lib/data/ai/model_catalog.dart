/// On-device model files. Downloaded ONCE by [LocalModelManager]; never
/// committed to git (see .gitignore). All sources are public and ungated,
/// so no Hugging Face token is needed.
class ModelSpec {
  const ModelSpec({
    required this.id,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
  });

  final String id;
  final String fileName;
  final String url;

  /// Exact size from the Hugging Face repo; used to verify a complete file.
  final int sizeBytes;
}

abstract final class ModelCatalog {
  /// Gemma 3 1B instruct, Q4_K_M GGUF (~806 MB). License: Gemma Terms of Use.
  static const llm = ModelSpec(
    id: 'llm',
    fileName: 'gemma-3-1b-it-Q4_K_M.gguf',
    url:
        'https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/'
        'gemma-3-1b-it-Q4_K_M.gguf',
    sizeBytes: 806058240,
  );

  /// Whisper base, multilingual (~148 MB). License: MIT.
  static const whisper = ModelSpec(
    id: 'whisper',
    fileName: 'ggml-base.bin',
    url:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'
        'ggml-base.bin',
    sizeBytes: 147951465,
  );

  /// EmbeddingGemma 300M, Q8_0 GGUF (~334 MB). License: Gemma Terms of Use.
  /// Embeds the driver's question for semantic retrieval; documents are
  /// pre-embedded in assets/data/embeddings.json (tools/build_embeddings.dart).
  static const embedder = ModelSpec(
    id: 'embedder',
    fileName: 'embeddinggemma-300M-Q8_0.gguf',
    url:
        'https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/'
        'embeddinggemma-300M-Q8_0.gguf',
    sizeBytes: 333590944,
  );

  static const all = [llm, whisper, embedder];
}
