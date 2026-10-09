import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../core/contracts/contracts.dart';

/// Local speech-to-text: records 16 kHz mono WAV with `record`, then runs
/// whisper.cpp (whisper_ggml) on the downloaded model file. No network.
class WhisperSpeechService implements SpeechService {
  WhisperSpeechService({required this.modelPath, this.language = 'tl'});

  /// Absolute path to the ggml Whisper model (from LocalModelManager).
  final String modelPath;

  /// 'tl' (Tagalog) handles Taglish best in testing; 'auto' is the fallback.
  final String language;

  /// Biases Whisper toward traffic/enforcement vocabulary.
  static const _initialPrompt =
      'Na-flag ako ng MMDA. LTO, multa, lisensya, beating the red light, '
      'swerving, number coding, counterflow, walang helmet.';

  final _recorder = AudioRecorder();
  String? _audioPath;

  @override
  Future<void> startListening() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission denied.');
    }
    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/buddy_speech.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _audioPath!,
    );
  }

  @override
  Future<String> stopAndTranscribe() async {
    final path = await _recorder.stop() ?? _audioPath;
    if (path == null || !File(path).existsSync()) return '';

    final response = await const Whisper(model: WhisperModel.base).transcribe(
      transcribeRequest: TranscribeRequest(
        audio: path,
        language: language,
        isNoTimestamps: true,
        initialPrompt: _initialPrompt,
      ),
      modelPath: modelPath,
    );
    return response.text.trim();
  }

  Future<void> dispose() => _recorder.dispose();
}
