import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/speech/mic_controller.dart';

const chatMicKey = 'chat';

/// Bottom input (thumb zone): big mic, text box, send — or a full-width
/// action button when [actionLabel] is set (two-sides steps). While
/// [streaming], send is disabled and a stop button is shown.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
        boxShadow: p.cardShadow,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(12),
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = !streaming && value.text.trim().isNotEmpty;
            void submit() => canSend ? onSubmit(value.text) : null;

            Widget roundButton({
              required Key key,
              required String tooltip,
              required Color bg,
              required Color fg,
              required VoidCallback? onPressed,
              required Widget icon,
            }) => SizedBox.square(
              dimension: 68,
              child: IconButton.filled(
                key: key,
                tooltip: tooltip,
                style: IconButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  disabledBackgroundColor: scheme.surfaceContainer,
                  disabledForegroundColor: p.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onPressed,
                icon: icon,
              ),
            );

            final stopButton = FilledButton.icon(
              key: const Key('chat-stop'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.inverseSurface,
                foregroundColor: scheme.onInverseSurface,
              ),
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Itigil'),
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    roundButton(
                      key: const Key('chat-mic'),
                      tooltip: listening ? 'Itigil at isulat' : 'Magsalita',
                      bg: listening ? p.accent : scheme.primary,
                      fg: listening ? p.onAccent : scheme.onPrimary,
                      onPressed: mic == MicPhase.transcribing
                          ? null
                          : () => _toggleMic(context, ref),
                      icon: mic == MicPhase.transcribing
                          ? const SizedBox.square(
                              dimension: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Icon(
                              listening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 36,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-input'),
                        controller: controller,
                        focusNode: focusNode,
                        style: context.text.titleMedium,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          hintText: switch (mic) {
                            MicPhase.listening => 'Nakikinig… (pindutin ulit)',
                            MicPhase.transcribing => 'Isinusulat…',
                            MicPhase.idle => hint,
                          },
                        ),
                      ),
                    ),
                    if (actionLabel == null) ...[
                      const SizedBox(width: 10),
                      streaming
                          ? roundButton(
                              key: const Key('chat-stop'),
                              tooltip: 'Itigil',
                              bg: scheme.inverseSurface,
                              fg: scheme.onInverseSurface,
                              onPressed: onStop,
                              icon: const Icon(Icons.stop_rounded, size: 36),
                            )
                          : roundButton(
                              key: const Key('chat-send'),
                              tooltip: 'Ipadala',
                              bg: p.accent,
                              fg: p.onAccent,
                              onPressed: canSend ? submit : null,
                              icon: const Icon(Icons.send_rounded, size: 32),
                            ),
                    ],
                  ],
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  if (streaming)
                    stopButton
                  else
                    FilledButton(
                      key: const Key('chat-action'),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                      ),
                      onPressed: canSend ? submit : null,
                      child: Text(actionLabel!),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
