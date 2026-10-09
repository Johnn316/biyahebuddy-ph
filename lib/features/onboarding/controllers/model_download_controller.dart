import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

enum DownloadPhase { idle, downloading, done, failed }

class ModelDownloadState {
  const ModelDownloadState({required this.phase, this.progress = 0});

  final DownloadPhase phase;

  /// 0.0..1.0
  final double progress;

  ModelDownloadState copyWith({DownloadPhase? phase, double? progress}) =>
      ModelDownloadState(
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
      );
}

class ModelDownloadController extends AutoDisposeNotifier<ModelDownloadState> {
  StreamSubscription<double>? _sub;

  @override
  ModelDownloadState build() {
    ref.onDispose(() => _sub?.cancel());
    return ref.read(modelManagerProvider).isReady
        ? const ModelDownloadState(phase: DownloadPhase.done, progress: 1)
        : const ModelDownloadState(phase: DownloadPhase.idle);
  }

  void start() {
    if (state.phase == DownloadPhase.downloading ||
        state.phase == DownloadPhase.done) {
      return;
    }
    state = const ModelDownloadState(phase: DownloadPhase.downloading);
    _sub = ref
        .read(modelManagerProvider)
        .downloadModels()
        .listen(
          (p) => state = state.copyWith(progress: p.clamp(0, 1)),
          onError: (Object _) =>
              state = state.copyWith(phase: DownloadPhase.failed),
          onDone: () {
            if (state.phase == DownloadPhase.downloading) {
              state = const ModelDownloadState(
                phase: DownloadPhase.done,
                progress: 1,
              );
            }
          },
        );
  }
}

final modelDownloadControllerProvider =
    NotifierProvider.autoDispose<ModelDownloadController, ModelDownloadState>(
      ModelDownloadController.new,
    );
