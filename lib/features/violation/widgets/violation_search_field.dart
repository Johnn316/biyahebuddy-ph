import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/speech/mic_controller.dart';
import '../controllers/violation_controller.dart';

const _micKey = 'violation';

/// Search box + mic (on-device SpeechService). Transcript fills the box.
class ViolationSearchField extends ConsumerWidget {
  const ViolationSearchField({super.key, required this.controller});

  final TextEditingController controller;

  Future<void> _toggleMic(BuildContext context, WidgetRef ref) async {
    try {
      final transcript = await ref
          .read(micControllerProvider(_micKey).notifier)
          .toggle();
      if (transcript == null) return;
      controller.text = transcript;
      ref.read(violationQueryProvider.notifier).state = transcript;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hindi ka marinig. I-type na lang.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mic = ref.watch(micControllerProvider(_micKey));
    ref.watch(violationQueryProvider); // rebuild for the clear (×) button
    final text = Theme.of(context).textTheme;
    final listening = mic == MicPhase.listening;

    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('violation-search'),
            controller: controller,
            style: text.titleLarge,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                ref.read(violationQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: switch (mic) {
                MicPhase.listening => 'Nakikinig… (pindutin ulit)',
                MicPhase.transcribing => 'Isinusulat…',
                MicPhase.idle => 'Hanapin ang violation',
              },
              hintStyle: text.bodyLarge,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Burahin',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        ref.read(violationQueryProvider.notifier).state = '';
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: AppSizes.minTap,
          child: IconButton.filled(
            key: const Key('mic'),
            tooltip: listening ? 'Itigil at isulat' : 'Magsalita',
            style: IconButton.styleFrom(
              backgroundColor: listening
                  ? context.palette.accent
                  : context.colors.primary,
              foregroundColor: listening
                  ? context.palette.onAccent
                  : context.colors.onPrimary,
            ),
            onPressed: mic == MicPhase.transcribing
                ? null
                : () => _toggleMic(context, ref),
            icon: mic == MicPhase.transcribing
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    listening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 32,
                  ),
          ),
        ),
      ],
    );
  }
}
