import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/model_download_controller.dart';

/// Step 1: one-time download of Buddy's on-device models.
class ModelDownloadStep extends ConsumerWidget {
  const ModelDownloadStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelDownloadControllerProvider);
    final controller = ref.read(modelDownloadControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final percent = (state.progress * 100).round();

    final (statusText, statusColor) = switch (state.phase) {
      DownloadPhase.idle => (
        'Kumonekta sa Wi-Fi o mobile data bago mag-download.',
        AppColors.onSurface,
      ),
      DownloadPhase.downloading => (
        'Dina-download… $percent%',
        AppColors.onSurface,
      ),
      DownloadPhase.done => (
        'Handa na si Buddy! Gagana na siya kahit walang signal.',
        AppColors.ok,
      ),
      DownloadPhase.failed => (
        'Hindi natuloy. I-check ang internet at subukan ulit.',
        AppColors.warning,
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: FittedBox(
                        child: Icon(
                          state.phase == DownloadPhase.done
                              ? Icons.check_circle
                              : Icons.download_for_offline,
                          size: 140,
                          color: state.phase == DownloadPhase.done
                              ? AppColors.ok
                              : AppColors.accent,
                        ),
                      ),
                    ),
                    Text(
                      'I-download si Buddy',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium,
                    ),
                    Text(
                      'Isang beses lang kailangan ng internet para '
                      'i-download si Buddy.',
                      textAlign: TextAlign.center,
                      style: text.titleLarge,
                    ),
                    Text(
                      'Pagkatapos nito, gagana na ang app kahit naka-airplane '
                      'mode o walang signal.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.gap),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                key: const Key('model-progress'),
                value: state.progress,
                minHeight: 28,
                color: state.phase == DownloadPhase.done
                    ? AppColors.ok
                    : AppColors.accent,
                backgroundColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: statusColor),
            ),
            const SizedBox(height: AppSizes.gap),
            switch (state.phase) {
              DownloadPhase.done => FilledButton.icon(
                key: const Key('model-continue'),
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Tuloy'),
              ),
              DownloadPhase.downloading => const FilledButton(
                onPressed: null,
                child: Text('Hintay lang…'),
              ),
              DownloadPhase.idle || DownloadPhase.failed => FilledButton.icon(
                key: const Key('model-download'),
                onPressed: controller.start,
                icon: const Icon(Icons.download),
                label: Text(
                  state.phase == DownloadPhase.failed
                      ? 'Subukan ulit'
                      : 'I-download si Buddy',
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}
