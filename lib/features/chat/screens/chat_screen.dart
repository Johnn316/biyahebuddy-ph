import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

// PLACEHOLDER — Offline AI chat (voice + text). For now it only shows the
// question box, prefilled from `/chat?q=<question>` (e.g. from Na-flag ako).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _question = TextEditingController(
    text: GoRouterState.of(context).uri.queryParameters['q'],
  );

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Text('Tanong kay Buddy'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Offline AI chat (voice + text)\n\n(coming soon)',
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                ),
              ),
              TextField(
                key: const Key('chat-input'),
                controller: _question,
                style: text.titleLarge,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Itanong kay Buddy…',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
