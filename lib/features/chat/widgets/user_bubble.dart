import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';

/// Driver's message: blue iMessage-style bubble, right-aligned.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.8)
              .clamp(0, 520)
              .toDouble(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.label != null)
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 4),
                child: Text(message.label!, style: context.text.bodySmall),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: p.primaryFill,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                message.text,
                style: context.text.bodyLarge?.copyWith(color: p.onPrimaryFill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
