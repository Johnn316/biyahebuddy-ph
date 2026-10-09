import 'package:llamadart/llamadart.dart';

/// Thin wrapper over llama.cpp (llamadart) running a local GGUF file.
/// Never downloads: the file must already be on disk (see LocalModelManager).
class LocalLlm {
  LlamaEngine? _engine;

  bool get isLoaded => _engine != null;

  Future<void> load(String ggufPath) async {
    if (_engine != null) return;
    _engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(ggufPath)),
      params: const ModelParams(
        contextSize: 2048,
        // CPU is predictable across phones; Android Vulkan is opt-in/experimental.
        device: ComputeDevice.cpu,
      ),
    );
  }

  /// Streams the answer token by token.
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 512,
  }) {
    final engine = _engine;
    if (engine == null) {
      throw StateError('LocalLlm.load() must be called first.');
    }
    return engine
        .create(
          [
            LlamaChatMessage.fromText(role: LlamaChatRole.system, text: system),
            LlamaChatMessage.fromText(role: LlamaChatRole.user, text: user),
          ],
          params: GenerationParams(maxTokens: maxTokens, temp: 0.3),
        )
        .textDeltas();
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
  }
}
