// AI spike debug app (backend only). Separate entrypoint so it never touches
// the real app's router or screens:
//
//   flutter run -t lib/data/debug/debug_ai_main.dart
//
// Download models once (Wi-Fi), then turn on airplane mode and test.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/local_llm.dart';
import '../ai/local_model_manager.dart';
import '../ai/model_catalog.dart';
import '../ai/whisper_speech_service.dart';

void main() => runApp(
  const MaterialApp(title: 'debug-ai', home: DebugAiScreen()),
);

const _spikeSystemPrompt =
    'Ikaw si Buddy, kalmadong katulong ng mga Pilipinong driver. '
    'Sumagot sa Taglish, maikli at malinaw. Huwag mag-imbento ng batas o '
    'halaga ng multa; kung hindi sigurado, sabihin ito. Huwag magdeklara ng '
    'pinal na legal na pagkakamali. Format:\n'
    'Kalma muna:\nAno ang sinasabi ng batas:\nPagsusuri:\nAno ang gagawin:';

const _testQuestions = [
  'Magkano multa pag walang helmet?',
  'Bigla siyang kumanan nang walang signal light, ako naman umabante, '
      'nagkabanggaan kami. Sino may mali?',
];

class DebugAiScreen extends StatefulWidget {
  const DebugAiScreen({super.key});

  @override
  State<DebugAiScreen> createState() => _DebugAiScreenState();
}

class _DebugAiScreenState extends State<DebugAiScreen> {
  final _models = LocalModelManager();
  late final _llm = LocalLlm(
    modelPath: () => _models.pathFor(ModelCatalog.llm),
  );
  WhisperSpeechService? _speech;
  final _question = TextEditingController(text: _testQuestions.first);

  double? _progress;
  bool _busy = false;
  bool _recording = false;
  String _answer = '';
  final _log = <String>[];

  @override
  void initState() {
    super.initState();
    _models.refresh().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _llm.dispose();
    _speech?.dispose();
    _question.dispose();
    super.dispose();
  }

  void _note(String line) => setState(() => _log.insert(0, line));

  Future<void> _download() async {
    setState(() => _progress = 0);
    try {
      await for (final p in _models.downloadModels()) {
        setState(() => _progress = p);
      }
      _note('Download done. ready=${_models.isReady}');
    } catch (e) {
      _note('Download error: $e');
    } finally {
      setState(() => _progress = null);
    }
  }

  Future<void> _ask() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _answer = '';
    });
    try {
      if (!_llm.isLoaded) {
        final sw = Stopwatch()..start();
        await _llm.load();
        _note('LLM load: ${sw.elapsedMilliseconds} ms');
      }
      final sw = Stopwatch()..start();
      int? firstTokenMs;
      await for (final piece in _llm.generate(
        system: _spikeSystemPrompt,
        user: _question.text,
      )) {
        firstTokenMs ??= sw.elapsedMilliseconds;
        setState(() => _answer += piece);
      }
      final totalS = sw.elapsedMilliseconds / 1000;
      _note(
        'LLM: first token ${firstTokenMs ?? '-'} ms, total '
        '${totalS.toStringAsFixed(1)} s, '
        '${(_answer.length / totalS).toStringAsFixed(0)} chars/s',
      );
    } catch (e) {
      _note('LLM error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _toggleMic() async {
    try {
      _speech ??= WhisperSpeechService(
        modelPath: () => _models.pathFor(ModelCatalog.whisper),
      );
      if (!_recording) {
        await _speech!.startListening();
        setState(() => _recording = true);
        return;
      }
      setState(() {
        _recording = false;
        _busy = true;
      });
      final sw = Stopwatch()..start();
      final text = await _speech!.stopAndTranscribe();
      _note('Whisper: ${sw.elapsedMilliseconds} ms → "$text"');
      _question.text = text;
    } catch (e) {
      _note('Speech error: $e');
      setState(() => _recording = false);
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _models.isReady;
    return Scaffold(
      appBar: AppBar(
        title: const Text('/debug-ai'),
        actions: [
          IconButton(
            tooltip: 'Copy log',
            icon: const Icon(Icons.copy),
            onPressed: () => Clipboard.setData(
              ClipboardData(text: '${_log.join('\n')}\n\n$_answer'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Models ready: $ready'),
          if (_progress != null) ...[
            LinearProgressIndicator(value: _progress),
            Text('${(_progress! * 100).toStringAsFixed(1)}%'),
          ] else if (!ready)
            FilledButton(
              onPressed: _download,
              child: const Text('Download models (~954 MB, once)'),
            ),
          const SizedBox(height: 12),
          TextField(controller: _question, maxLines: 3),
          Wrap(
            spacing: 8,
            children: [
              for (final q in _testQuestions)
                ActionChip(
                  label: Text(q, overflow: TextOverflow.ellipsis),
                  onPressed: () => _question.text = q,
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: ready && !_busy ? _ask : null,
                  child: const Text('Ask LLM'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 32,
                onPressed: ready && (!_busy || _recording) ? _toggleMic : null,
                icon: Icon(_recording ? Icons.stop : Icons.mic),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          SelectableText(_answer),
          const Divider(),
          for (final line in _log) Text(line),
        ],
      ),
    );
  }
}
