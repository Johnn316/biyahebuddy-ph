import 'dart:async';

import 'package:llamadart/llamadart.dart';

/// Something that streams generated text. Lets the assistant be tested with a
/// fake instead of a real model.
abstract interface class TextGenerator {
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens,
  });
}

/// llama.cpp (llamadart) running a local GGUF file on the CPU.
///
/// Never downloads: [modelPath] must point to a file LocalModelManager already
/// fetched. Loads lazily on first use. Runs one generation at a time; a
/// cancelled stream subscription stops native generation.
class LocalLlm implements TextGenerator {
  LocalLlm({required this.modelPath});

  final Future<String> Function() modelPath;

  LlamaEngine? _engine;
  Future<LlamaEngine>? _loading;
  Future<void> _tail = Future.value();

  bool get isLoaded => _engine != null;

  /// Loads the model if needed (~3–10 s). Safe to call repeatedly.
  Future<void> load() => _ensureLoaded();

  Future<LlamaEngine> _ensureLoaded() async {
    if (_engine != null) return _engine!;
    _loading ??= () async {
      try {
        return _engine = await LlamaEngine.load(
          LlamaModel(ModelSource.path(await modelPath())),
          params: const ModelParams(
            contextSize: 2048,
            // CPU is predictable across phones; Android Vulkan is opt-in.
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
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 160,
  }) async* {
    // Queue behind any running generation.
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    LlamaEngine? engine;
    var finished = false;
    try {
      await previous;
      engine = await _ensureLoaded();
      yield* engine
          .create(
            [
              LlamaChatMessage.fromText(
                role: LlamaChatRole.system,
                text: system,
              ),
              LlamaChatMessage.fromText(role: LlamaChatRole.user, text: user),
            ],
            // penalty > default 1.1: a 1B model loops otherwise.
            params: GenerationParams(
              maxTokens: maxTokens,
              temp: 0.3,
              penalty: 1.25,
            ),
          )
          .textDeltas();
      finished = true;
    } finally {
      // Runs on error and when the listener cancels (user tapped Stop).
      if (!finished) engine?.cancelGeneration();
      done.complete();
    }
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
  }
}
