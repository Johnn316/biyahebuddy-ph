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
    final text = Theme.of(context).textTheme;
    final listening = mic == MicPhase.listening;

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(12),
        child: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = !streaming && value.text.trim().isNotEmpty;
            void submit() => canSend ? onSubmit(value.text) : null;

            final stopButton = FilledButton.icon(
              key: const Key('chat-stop'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Itigil'),
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox.square(
                      dimension: 72,
                      child: IconButton.filled(
                        key: const Key('chat-mic'),
                        tooltip: listening ? 'Itigil at isulat' : 'Magsalita',
                        style: IconButton.styleFrom(
                          backgroundColor: listening
                              ? AppColors.accent
                              : AppColors.primary,
                          foregroundColor: listening
                              ? Colors.black
                              : Colors.white,
                        ),
                        onPressed: mic == MicPhase.transcribing
                            ? null
                            : () => _toggleMic(context, ref),
                        icon: mic == MicPhase.transcribing
                            ? const SizedBox.square(
                                dimension: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                listening ? Icons.stop : Icons.mic,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-input'),
                        controller: controller,
                        focusNode: focusNode,
                        style: text.titleLarge,
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
                          hintStyle: text.bodyLarge,
                          filled: true,
                          fillColor: AppColors.background,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (actionLabel == null) ...[
                      const SizedBox(width: 8),
                      SizedBox.square(
                        dimension: 72,
                        child: streaming
                            ? IconButton.filled(
                                key: const Key('chat-stop'),
                                tooltip: 'Itigil',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: onStop,
                                icon: const Icon(Icons.stop, size: 40),
                              )
                            : IconButton.filled(
                                key: const Key('chat-send'),
                                tooltip: 'Ipadala',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.white12,
                                ),
                                onPressed: canSend ? submit : null,
                                icon: const Icon(Icons.send, size: 36),
                              ),
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
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
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
