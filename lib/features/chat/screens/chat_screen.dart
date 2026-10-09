import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/chat_controller.dart';
import '../widgets/buddy_answer.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/flag_widgets.dart';
import '../widgets/topic_widgets.dart';
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

  /// Tap on Stop → the answer being typed out freezes.
  final _stopSignal = ValueNotifier<int>(0);

  /// An answer is still being revealed word by word (stream may be done).
  bool _revealing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.toString() == _appliedQ) return;
    _appliedQ = uri.toString();
    final q = uri.queryParameters['q'];
    if (q != null) _input.text = q;
    // Home's Ask field: open with the keyboard up.
    if (q != null || uri.queryParameters['focus'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    _stopSignal.dispose();
    super.dispose();
  }

  ChatController get _chat => ref.read(chatControllerProvider.notifier);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(force: true));
  }

  /// Keeps the newest words in view: a short glide (a jump under reduce
  /// motion). Doesn't fight a driver who scrolled up to re-read.
  void _follow({bool force = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final gap = pos.maxScrollExtent - pos.pixels;
    if (gap <= 0.5 || (!force && gap > 240)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(pos.maxScrollExtent);
    } else {
      _scroll.animateTo(
        pos.maxScrollExtent,
        duration: AppMotion.quick,
        curve: AppMotion.enter,
      );
    }
  }

  void _setRevealing(bool v) {
    if (mounted && v != _revealing) setState(() => _revealing = v);
  }

  void _stop() {
    if (ref.read(chatControllerProvider).streaming) _chat.stop();
    _stopSignal.value++;
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

  /// What sits under a Buddy message: na-flag chips/card, topic menus, or
  /// the topic's other questions after an answer.
  Widget? _footerFor(ChatMessage m, {String? asked, required bool busy}) {
    if (m.flag != null) {
      return FlagFooter(
        message: m,
        onChip: (violation, agency) {
          if (!busy) _chat.answerViolation(violation, agency);
        },
      );
    }
    void showTopics() {
      if (!busy) _chat.showTopics();
    }

    void askTopic(String q, String topic) {
      if (!busy) _chat.ask(q, topic: topic);
    }

    final topic = topicById(m.topic);
    return switch (m.menu) {
      TopicMenu.topics => TopicGrid(
        onTap: (t) {
          if (!busy) _chat.openTopic(t.id);
        },
      ),
      TopicMenu.questions when topic != null => TopicQuestions(
        topic: topic,
        onQuestion: (q) => askTopic(q, topic.id),
        onBack: showTopics,
      ),
      null when topic != null => TopicFollowUps(
        topic: topic,
        asked: asked,
        onQuestion: (q) => askTopic(q, topic.id),
        onAll: showTopics,
      ),
      _ => null,
    };
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
    final busy = state.streaming || _revealing;

    // [bottom] = frosted input bar + tab bar + safe area. Read INSIDE the
    // Scaffold body (extendBody adds the input bar there), so nothing is
    // ever hidden behind the bar.
    Widget body(double bottom) => switch (state) {
      ChatState(mode: ChatMode.ask, askMessages: []) => _EmptyAsk(
        bottom: bottom,
        onTopic: (t) => _chat.openTopic(t.id),
      ),
      _ when !twoSides || showResult => ListView.separated(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          bottom + AppSpace.md,
        ),
        itemCount: state.visibleMessages.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xl),
        itemBuilder: (_, i) {
          final m = state.visibleMessages[i];
          return m.role == ChatRole.user
              ? UserBubble(message: m)
              : BuddyAnswer(
                  key: ValueKey('answer-${state.mode.name}-$i'),
                  message: m,
                  stopSignal: _stopSignal,
                  onRevealing: _setRevealing,
                  onGrow: _follow,
                  footer: _footerFor(
                    m,
                    asked: i > 0 ? state.visibleMessages[i - 1].text : null,
                    busy: busy,
                  ),
                );
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
            const SizedBox(width: AppSpace.sm),
            Text('Buddy', maxLines: 1, style: context.text.titleLarge),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: _OfflineDot(
                ready: ref.watch(modelManagerProvider).isReady,
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
                backgroundColor: p.elevated.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(3),
                children: {
                  for (final (m, label) in [
                    (ChatMode.ask, 'Tanong'),
                    (ChatMode.twoSides, 'Dalawang panig'),
                  ])
                    m: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: context.text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                },
                onValueChanged: (m) {
                  if (m == null || busy) return;
                  HapticFeedback.selectionClick();
                  _input.clear();
                  _chat.setMode(m);
                },
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) =>
                    body(MediaQuery.paddingOf(context).bottom),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FrostedBottom(
        child: ContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showResult && !busy)
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
                  streaming: busy,
                  onSubmit: _submit,
                  onStop: _stop,
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
  const _EmptyAsk({required this.bottom, required this.onTopic});

  /// Input bar + tab bar + safe area: the content stays above it.
  final double bottom;
  final ValueChanged<BuddyTopic> onTopic;

  @override
  Widget build(BuildContext context) {
    // Category tiles; scrolls, never hidden behind the input bar.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: const Key('chat-empty'),
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          bottom + AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ano ang tanong mo?',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'Pumili ng topic, o i-type ang tanong mo sa ibaba.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TopicGrid(width: box.maxWidth - 2 * AppSpace.md, onTap: onTopic),
          ],
        ),
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

/// Small status dot next to "Buddy": green "Offline" when the AI is on the
/// phone, amber "I-download" when it isn't yet.
class _OfflineDot extends StatelessWidget {
  const _OfflineDot({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = ready ? p.success : p.cautionText;
    return Semantics(
      label: ready
          ? 'Offline-ready. Gumagana si Buddy kahit walang signal.'
          : 'Hindi pa naka-download si Buddy.',
      excludeSemantics: true,
      child: Row(
        key: const Key('offline-badge'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              ready ? 'Offline' : 'I-download',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
