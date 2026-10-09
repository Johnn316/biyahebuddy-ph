import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../widgets/buddy_answer.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/user_bubble.dart';

/// "Tanong kay Buddy". `/chat?q=<text>` prefills the box (never auto-sends).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final _input = TextEditingController(
    text: GoRouterState.of(context).uri.queryParameters['q'],
  );
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ChatController get _chat => ref.read(chatControllerProvider.notifier);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _submit(String text) {
    final state = ref.read(chatControllerProvider);
    switch ((state.mode, state.twoSidesStep)) {
      case (ChatMode.ask, _):
        _chat.ask(text);
      case (ChatMode.twoSides, TwoSidesStep.sideA):
        _chat.submitSideA(text);
      case (ChatMode.twoSides, _):
        _chat.analyze(text);
    }
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _quickQuestion(String q) {
    if (q.endsWith('…')) {
      // Unfinished question: put it in the box for the driver to complete.
      _input.text = '${q.substring(0, q.length - 1)} ';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      _inputFocus.requestFocus();
    } else {
      _chat.ask(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.visibleMessages != next.visibleMessages) _scrollToBottom();
    });
    final text = Theme.of(context).textTheme;
    final twoSides = state.mode == ChatMode.twoSides;
    final showResult = twoSides && state.twoSidesStep == TwoSidesStep.result;

    final Widget body = switch (state) {
      ChatState(mode: ChatMode.ask, askMessages: []) => const _EmptyAsk(),
      _ when !twoSides || showResult => ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: state.visibleMessages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final m = state.visibleMessages[i];
          return m.role == ChatRole.user
              ? UserBubble(message: m)
              : BuddyAnswer(message: m);
        },
      ),
      _ => _TwoSidesPrompt(
        step: state.twoSidesStep,
        sideA: state.sideA,
        onEditSideA: () {
          _input.text = state.sideA;
          _chat.backToSideA();
        },
      ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buddy'),
            Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: AppColors.ok),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Gumagana kahit walang signal',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.ok,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SegmentedButton<ChatMode>(
              key: const Key('chat-mode'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: text.titleLarge,
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: Colors.black,
              ),
              segments: const [
                ButtonSegment(
                  value: ChatMode.ask,
                  icon: Icon(Icons.chat),
                  label: Text('Tanong'),
                ),
                ButtonSegment(
                  value: ChatMode.twoSides,
                  icon: Icon(Icons.balance),
                  label: Text('Dalawang panig'),
                ),
              ],
              selected: {state.mode},
              onSelectionChanged: state.streaming
                  ? null
                  : (s) {
                      _input.clear();
                      _chat.setMode(s.single);
                    },
            ),
          ),
          Expanded(child: body),
          if (state.mode == ChatMode.ask && state.askMessages.isEmpty)
            _QuickChips(onTap: _quickQuestion),
          if (showResult && !state.streaming)
            SafeArea(
              top: false,
              minimum: const EdgeInsets.all(12),
              child: FilledButton.icon(
                key: const Key('new-case'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  _input.clear();
                  _chat.newCase();
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Bagong kaso'),
              ),
            )
          else
            ChatInputBar(
              controller: _input,
              focusNode: _inputFocus,
              hint: switch ((state.mode, state.twoSidesStep)) {
                (ChatMode.ask, _) => 'Itanong kay Buddy…',
                (_, TwoSidesStep.sideA) => 'Ikuwento ang nangyari…',
                _ => 'Ano ang sabi niya…',
              },
              actionLabel: switch ((state.mode, state.twoSidesStep)) {
                (ChatMode.ask, _) => null,
                (_, TwoSidesStep.sideA) => 'Susunod',
                _ => 'Suriin',
              },
              streaming: state.streaming,
              onSubmit: _submit,
              onStop: _chat.stop,
            ),
        ],
      ),
    );
  }
}

class _EmptyAsk extends StatelessWidget {
  const _EmptyAsk();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Fills the space; scrolls instead of overflowing on short screens.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.gap),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - 2 * AppSizes.gap).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (box.maxHeight > 260)
                const Icon(
                  Icons.support_agent,
                  size: 110,
                  color: AppColors.primary,
                ),
              Text(
                'Ano ang gusto mong itanong kay Buddy?',
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Batas trapiko, multa, aksidente — magsalita o mag-type.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // One swipeable row: keeps the input visible even with the keyboard open.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          for (final (i, q) in quickQuestions.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: Key('quick-$i'),
                label: Text(q),
                labelStyle: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                side: const BorderSide(color: AppColors.accent, width: 2),
                onPressed: () => onTap(q),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two sides, steps A and B: a big prompt filling the screen.
class _TwoSidesPrompt extends StatelessWidget {
  const _TwoSidesPrompt({
    required this.step,
    required this.sideA,
    required this.onEditSideA,
  });

  final TwoSidesStep step;
  final String sideA;
  final VoidCallback onEditSideA;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isA = step == TwoSidesStep.sideA;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isA ? 'Hakbang 1 ng 2' : 'Hakbang 2 ng 2',
            style: text.titleLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            isA
                ? 'Ano ang nangyari sa panig mo?'
                : 'Ano ang sabi ng kabilang driver?',
            key: const Key('two-sides-prompt'),
            style: text.displayLarge?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 12),
          Text(
            isA
                ? 'Hal. "Nauna akong pumasok sa intersection, bigla siyang '
                      'lumiko pakaliwa."'
                : 'Ilagay ang kuwento niya kahit hindi ka sang-ayon. Si Buddy '
                      'ang titingin sa dalawang panig.',
            style: text.bodyLarge?.copyWith(color: Colors.white70),
          ),
          if (!isA) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panig mo',
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  Text(sideA, style: text.bodyLarge),
                  TextButton.icon(
                    key: const Key('edit-side-a'),
                    onPressed: onEditSideA,
                    icon: const Icon(Icons.edit),
                    label: const Text('Baguhin'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
