import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

enum MicPhase { idle, listening, transcribing }

/// Mic toggle: tap to start listening, tap again to transcribe (on-device
/// SpeechService). One instance per screen key, e.g. 'violation', 'chat'.
class MicController extends AutoDisposeFamilyNotifier<MicPhase, String> {
  @override
  MicPhase build(String screen) => MicPhase.idle;

  /// Returns the transcript when stopping; null when starting or busy.
  /// Throws if the speech service fails (state is reset to idle).
  Future<String?> toggle() async {
    final speech = ref.read(speechServiceProvider);
    switch (state) {
      case MicPhase.idle:
        state = MicPhase.listening;
        try {
          await speech.startListening();
        } catch (_) {
          state = MicPhase.idle;
          rethrow;
        }
        return null;
      case MicPhase.listening:
        state = MicPhase.transcribing;
        try {
          return (await speech.stopAndTranscribe()).trim();
        } finally {
          state = MicPhase.idle;
        }
      case MicPhase.transcribing:
        return null;
    }
  }
}

final micControllerProvider = NotifierProvider.autoDispose
    .family<MicController, MicPhase, String>(MicController.new);
