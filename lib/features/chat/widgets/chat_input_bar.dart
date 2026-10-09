import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/features.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/speech/mic_controller.dart';

const chatMicKey = 'chat';

/// Bottom input (thumb zone): rounded text pill with the send button inside
/// (mic on the left only when [kVoiceInputEnabled]) — or a full-width action
/// button when [actionLabel] is set (two-sides steps). While [streaming],
/// send is replaced by a stop button.
/// Transparent: the parent provides the frosted background.
class ChatInputBar extends ConsumerWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    required this.onSubmit,
    required this.streaming,
    required this.onStop,
    this.actionLabel,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String> onSubmit;
  final bool streaming;
  final VoidCallback onStop;
  final String? actionLabel;

  Future<void> _toggleMic(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    try {
      final transcript = await ref
          .read(micControllerProvider(chatMicKey).notifier)
          .toggle();
      if (transcript == null || transcript.isEmpty) return;
      controller.text = transcript;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hindi ka marinig. I-type na lang.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mic = ref.watch(micControllerProvider(chatMicKey));
    final scheme = context.colors;
    final p = context.palette;
    final listening = mic == MicPhase.listening;

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final canSend = !streaming && value.text.trim().isNotEmpty;
        void submit() {
          if (!canSend) return;
          HapticFeedback.lightImpact();
          onSubmit(value.text);
        }

        Widget round({
          required Key key,
          required String tooltip,
          required Color bg,
          required Color fg,
          required VoidCallback? onPressed,
          required Widget icon,
          double size = 56,
        }) => SizedBox.square(
          dimension: size,
          child: IconButton.filled(
            key: key,
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: p.elevated,
              disabledForegroundColor: p.muted,
              shape: const CircleBorder(),
            ),
            onPressed: onPressed,
            icon: icon,
          ),
        );

        // Send / stop live inside the pill (iMessage-style).
        final inlineButton = actionLabel != null
            ? null
            : Padding(
                padding: const EdgeInsets.all(5),
                child: streaming
                    ? round(
                        key: const Key('chat-stop'),
                        tooltip: 'Itigil',
                        bg: scheme.inverseSurface,
                        fg: scheme.onInverseSurface,
                        size: 44,
                        onPressed: onStop,
                        icon: const Icon(CupertinoIcons.stop_fill, size: 20),
                      )
                    : round(
                        key: const Key('chat-send'),
                        tooltip: 'Ipadala',
                        bg: p.primaryFill,
                        fg: p.onPrimaryFill,
                        size: 44,
                        onPressed: canSend ? submit : null,
                        icon: const Icon(CupertinoIcons.arrow_up, size: 22),
                      ),
              );
        final pill = BorderRadius.circular(AppRadius.lg + 2);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (kVoiceInputEnabled) ...[
                  round(
                    key: const Key('chat-mic'),
                    tooltip: listening ? 'Itigil at isulat' : 'Magsalita',
                    bg: listening ? p.accent : p.primaryFill,
                    fg: listening ? p.onAccent : p.onPrimaryFill,
                    size: 54,
                    onPressed: mic == MicPhase.transcribing
                        ? null
                        : () => _toggleMic(context, ref),
                    icon: mic == MicPhase.transcribing
                        ? const CupertinoActivityIndicator()
                        : Icon(
                            listening
                                ? CupertinoIcons.stop_fill
                                : CupertinoIcons.mic_fill,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                ],
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: controller,
                    focusNode: focusNode,
                    style: context.text.bodyLarge,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.fromLTRB(
                        AppSpace.md + 2,
                        16,
                        AppSpace.xs,
                        16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: pill,
                        borderSide: BorderSide(color: p.controlOutline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: pill,
                        borderSide: BorderSide(
                          color: scheme.outline,
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: pill,
                        borderSide: BorderSide(
                          color: scheme.primary,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: inlineButton,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 54,
                        minHeight: 54,
                      ),
                      hintText: switch (mic) {
                        MicPhase.listening => 'Nakikinig… (pindutin ulit)',
                        MicPhase.transcribing => 'Isinusulat…',
                        MicPhase.idle => hint,
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 10),
              if (streaming)
                FilledButton.icon(
                  key: const Key('chat-stop'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.inverseSurface,
                    foregroundColor: scheme.onInverseSurface,
                  ),
                  onPressed: onStop,
                  icon: const Icon(CupertinoIcons.stop_fill),
                  label: const Text('Itigil'),
                )
              else
                FilledButton(
                  key: const Key('chat-action'),
                  onPressed: canSend ? submit : null,
                  child: Text(actionLabel!),
                ),
            ],
          ],
        );
      },
    );
  }
}
