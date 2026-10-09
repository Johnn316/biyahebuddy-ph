import '../contracts/contracts.dart';

/// Pretends to record and returns a canned Taglish transcript.
class FakeSpeechService implements SpeechService {
  bool _listening = false;

  @override
  Future<void> startListening() async => _listening = true;

  @override
  Future<String> stopAndTranscribe() async {
    if (!_listening) return '';
    _listening = false;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'Na-flag ako ng MMDA dahil sa swerving, magkano ang multa?';
  }
}
