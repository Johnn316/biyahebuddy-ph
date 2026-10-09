import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../../shared/widgets/pressable.dart';
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

  void _quickQuestion(String q) {
    HapticFeedback.lightImpact();
    _chat.ask(q);
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
    final busy = state.streaming || _revealing;

    final Widget body = switch (state) {
      ChatState(mode: ChatMode.ask, askMessages: []) => _EmptyAsk(
        bottom: bottom,
        onAsk: _quickQuestion,
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
  const _EmptyAsk({required this.bottom, required this.onAsk});

  final double bottom;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    // Fills the space; scrolls instead of overflowing on short screens.
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxHeight - bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.md,
            AppSpace.md,
            bottom + AppSpace.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (room - 2 * AppSpace.md).clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (room > 420)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpace.md),
                    child: Center(child: BuddyAvatar(size: 76)),
                  ),
                Text(
                  'Ano ang gusto mong itanong?',
                  textAlign: TextAlign.center,
                  style: context.text.headlineMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Batas trapiko, multa, aksidente — sagot kahit offline.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                _Suggestions(
                  width: box.maxWidth - 2 * AppSpace.md,
                  onTap: onAsk,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 2×2 suggestion cards (one column when text is huge); tap = send.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.width, required this.onTap});

  final double width;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final icons = [
      (CupertinoIcons.tag_fill, p.cautionText),
      (CupertinoIcons.car_detailed, context.colors.primary),
      (CupertinoIcons.exclamationmark_triangle_fill, p.cautionText),
      (CupertinoIcons.flag_fill, p.success),
    ];
    final cards = [
      for (final (i, q) in quickQuestions.indexed)
        _SuggestionCard(
          tapKey: Key('quick-$i'),
          text: q,
          icon: icons[i].$1,
          color: icons[i].$2,
          onTap: () => onTap(q),
        ),
    ];
    if ((width - AppSpace.sm) / 2 < 150 * scale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in cards.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpace.sm),
            c,
          ],
        ],
      );
    }
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: b),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(cards[0], cards[1]),
        const SizedBox(height: AppSpace.sm),
        row(cards[2], cards[3]),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.tapKey,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Key tapKey;
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      label: 'Itanong: $text',
      excludeSemantics: true,
      child: Pressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: radius,
            boxShadow: p.cardShadow,
            border: Border(top: BorderSide(color: p.highlight, width: 0.5)),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: tapKey,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      text,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
