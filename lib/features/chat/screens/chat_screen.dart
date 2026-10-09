import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/chat_controller.dart';
import '../widgets/buddy_answer.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/user_bubble.dart';

/// "Tanong kay Buddy" tab. `/chat?q=<text>` prefills the box (never
/// auto-sends) — also when the tab already exists. History lives as long as
/// the app session (tabs keep their state).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  String? _appliedQ;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['q'];
    if (q != null && q != _appliedQ) {
      _appliedQ = q;
      _input.text = q;
    }
  }

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
    HapticFeedback.selectionClick();
    if (q.endsWith('…')) {
      // Unfinished question: put it in the box for the driver to complete.
      _input.text = '${q.substring(0, q.length - 1)} ';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      _inputFocus.requestFocus();
    } else {
      _chat.ask(q);
    }
  }

  Future<void> _newCase() async {
    final ok = await confirmWithSheet(
      context,
      title: 'Bagong kaso?',
      message: 'Mabubura ang kasalukuyang pagsusuri.',
      confirmLabel: 'Magsimula ulit',
      destructive: false,
    );
    if (!ok || !mounted) return;
    _input.clear();
    _chat.newCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.visibleMessages != next.visibleMessages) _scrollToBottom();
    });
    final p = context.palette;
    final twoSides = state.mode == ChatMode.twoSides;
    final showResult = twoSides && state.twoSidesStep == TwoSidesStep.result;
    // Room for the frosted input area (body extends behind it).
    final bottom = MediaQuery.paddingOf(context).bottom;

    final Widget body = switch (state) {
      ChatState(mode: ChatMode.ask, askMessages: []) => _EmptyAsk(
        bottom: bottom,
      ),
      _ when !twoSides || showResult => ListView.separated(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(14, 12, 14, bottom + 16),
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
        bottom: bottom,
        onEditSideA: () {
          _input.text = state.sideA;
          _chat.backToSideA();
        },
      ),
    };

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            const BuddyAvatar(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buddy', style: context.text.titleLarge),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.wifi_slash,
                        size: 14,
                        color: p.success,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Gumagana kahit walang signal',
                            style: context.text.labelMedium?.copyWith(
                              color: p.success,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: CupertinoSlidingSegmentedControl<ChatMode>(
                key: const Key('chat-mode'),
                groupValue: state.mode,
                thumbColor: context.colors.surface,
                backgroundColor: p.elevated,
                padding: const EdgeInsets.all(4),
                children: {
                  for (final (m, icon, label) in [
                    (ChatMode.ask, CupertinoIcons.chat_bubble_fill, 'Tanong'),
                    (
                      ChatMode.twoSides,
                      CupertinoIcons.person_2_fill,
                      'Dalawang panig',
                    ),
                  ])
                    m: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                },
                onValueChanged: (m) {
                  if (m == null || state.streaming) return;
                  HapticFeedback.selectionClick();
                  _input.clear();
                  _chat.setMode(m);
                },
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: _FrostedBottom(
        child: ContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.mode == ChatMode.ask && state.askMessages.isEmpty)
                _QuickChips(onTap: _quickQuestion),
              if (showResult && !state.streaming)
                FilledButton.icon(
                  key: const Key('new-case'),
                  onPressed: _newCase,
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                  label: const Text('Bagong kaso'),
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
        ),
      ),
    );
  }
}

/// Translucent, blurred bottom area (content scrolls behind it).
class _FrostedBottom extends StatelessWidget {
  const _FrostedBottom({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.groupedBackground.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: context.colors.outline.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmptyAsk extends StatelessWidget {
  const _EmptyAsk({required this.bottom});

  final double bottom;

  @override
  Widget build(BuildContext context) {
    // Fills the space; scrolls instead of overflowing on short screens.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - bottom - 32).clamp(0, double.infinity),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (box.maxHeight - bottom > 280)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: BuddyAvatar(size: 88),
                ),
              Text(
                'Ano ang gusto mong itanong kay Buddy?',
                textAlign: TextAlign.center,
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Batas trapiko, multa, aksidente — magsalita o mag-type.',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: context.palette.muted,
                ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (final (i, q) in quickQuestions.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: Key('quick-$i'),
                label: Text(q),
                labelStyle: context.text.titleSmall?.copyWith(
                  color: context.colors.primary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
    required this.bottom,
    required this.onEditSideA,
  });

  final TwoSidesStep step;
  final String sideA;
  final double bottom;
  final VoidCallback onEditSideA;

  @override
  Widget build(BuildContext context) {
    final isA = step == TwoSidesStep.sideA;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isA ? 'HAKBANG 1 NG 2' : 'HAKBANG 2 NG 2',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isA
                ? 'Ano ang nangyari sa panig mo?'
                : 'Ano ang sabi ng kabilang driver?',
            key: const Key('two-sides-prompt'),
            style: context.text.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            isA
                ? 'Hal. "Nauna akong pumasok sa intersection, bigla siyang '
                      'lumiko pakaliwa."'
                : 'Ilagay ang kuwento niya kahit hindi ka sang-ayon. Si Buddy '
                      'ang titingin sa dalawang panig.',
            style: context.text.bodyLarge?.copyWith(
              color: context.palette.muted,
            ),
          ),
          if (!isA)
            GroupedSection(
              header: 'Panig mo',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(sideA, style: context.text.bodyLarge),
                ),
                GroupedTile(
                  tapKey: const Key('edit-side-a'),
                  leading: Icon(
                    CupertinoIcons.pencil,
                    color: context.colors.primary,
                  ),
                  title: 'Baguhin',
                  titleStyle: context.text.titleMedium?.copyWith(
                    color: context.colors.primary,
                  ),
                  chevron: false,
                  onTap: onEditSideA,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
