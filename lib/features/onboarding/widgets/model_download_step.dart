import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/scale_down_to_fit.dart';
import '../controllers/model_download_controller.dart';

/// Step 1: one-time download of Buddy's on-device models.
class ModelDownloadStep extends ConsumerWidget {
  const ModelDownloadStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelDownloadControllerProvider);
    final controller = ref.read(modelDownloadControllerProvider.notifier);
    final p = context.palette;
    final percent = (state.progress * 100).round();
    final done = state.phase == DownloadPhase.done;
    final heroColor = done ? p.success : context.colors.primary;

    final (statusText, statusColor) = switch (state.phase) {
      DownloadPhase.idle => (
        'Kumonekta sa Wi-Fi o mobile data bago mag-download.',
        p.muted,
      ),
      DownloadPhase.downloading => (
        'Dina-download… $percent%',
        context.colors.onSurface,
      ),
      DownloadPhase.done => (
        'Handa na si Buddy! Gagana na siya kahit walang signal.',
        p.success,
      ),
      DownloadPhase.failed => (
        'Hindi natuloy. I-check ang internet at subukan ulit.',
        p.accent,
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: ScaleDownToFit(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: heroColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.download_for_offline_rounded,
                          size: 96,
                          color: heroColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'I-download si Buddy',
                        textAlign: TextAlign.center,
                        style: context.text.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Isang beses lang kailangan ng internet para '
                        'i-download si Buddy.',
                        textAlign: TextAlign.center,
                        style: context.text.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: p.success),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Pagkatapos nito, gagana na ang app kahit '
                              'naka-airplane mode.',
                              textAlign: TextAlign.center,
                              style: context.text.bodyLarge?.copyWith(
                                color: p.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const Key('model-progress'),
                value: state.progress,
                minHeight: 18,
                color: done ? p.success : p.accent,
                backgroundColor: context.colors.surfaceContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(color: statusColor),
            ),
            const SizedBox(height: AppSizes.gap),
            switch (state.phase) {
              DownloadPhase.done => FilledButton.icon(
                key: const Key('model-continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: p.success,
                  foregroundColor: p.onSuccess,
                ),
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Tuloy'),
              ),
              DownloadPhase.downloading => const FilledButton(
                onPressed: null,
                child: Text('Hintay lang…'),
              ),
              DownloadPhase.idle || DownloadPhase.failed => FilledButton.icon(
                key: const Key('model-download'),
                onPressed: controller.start,
                icon: const Icon(Icons.download_rounded),
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
