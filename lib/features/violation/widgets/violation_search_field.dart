import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/speech/mic_controller.dart';
import '../controllers/violation_controller.dart';

const _micKey = 'violation';

/// iOS-style search pill + mic (on-device SpeechService). Transcript fills
/// the box.
class ViolationSearchField extends ConsumerWidget {
  const ViolationSearchField({super.key, required this.controller});

  final TextEditingController controller;

  Future<void> _toggleMic(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
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
    final listening = mic == MicPhase.listening;
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('violation-search'),
            controller: controller,
            style: context.text.titleMedium,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                ref.read(violationQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              filled: true,
              fillColor: p.elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.colors.primary),
              ),
              hintText: switch (mic) {
                MicPhase.listening => 'Nakikinig… (pindutin ulit)',
                MicPhase.transcribing => 'Isinusulat…',
                MicPhase.idle => 'Hanapin ang violation',
              },
              prefixIcon: Icon(CupertinoIcons.search, color: p.muted),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Burahin',
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: p.muted,
                      ),
                      onPressed: () {
                        controller.clear();
                        ref.read(violationQueryProvider.notifier).state = '';
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox.square(
          dimension: 56,
          child: IconButton.filled(
            key: const Key('mic'),
            tooltip: listening ? 'Itigil at isulat' : 'Magsalita',
            style: IconButton.styleFrom(
              backgroundColor: listening ? p.accent : context.colors.primary,
              foregroundColor: listening
                  ? p.onAccent
                  : context.colors.onPrimary,
            ),
            onPressed: mic == MicPhase.transcribing
                ? null
                : () => _toggleMic(context, ref),
            icon: mic == MicPhase.transcribing
                ? const CupertinoActivityIndicator()
                : Icon(
                    listening
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic_fill,
                    size: 28,
                  ),
          ),
        ),
      ],
    );
  }
}
