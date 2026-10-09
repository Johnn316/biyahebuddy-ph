import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';

/// Driver's message, right-aligned.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.label != null)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: Text(
                  message.label!,
                  style: text.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(message.text, style: text.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
