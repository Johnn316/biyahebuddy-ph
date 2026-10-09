import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/law_pill.dart';
import '../controllers/answer_format.dart';
import '../controllers/answer_reveal.dart';
import '../controllers/chat_controller.dart';
import 'law_sheet.dart';

const answerDisclaimer = 'Gabay batay sa batas, hindi legal na hatol.';

/// Section label color (text only — no icon badges).
Color _labelColor(BuildContext context, AnswerSectionKind k) => switch (k) {
  AnswerSectionKind.kalma => context.palette.success,
  AnswerSectionKind.batas => context.palette.cautionText,
  _ => context.colors.primary,
};

/// Buddy avatar: blue gradient circle with a soft ring.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size > 48 ? 3 : 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: p.ringGradient,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.primaryFill,
          ),
          child: Icon(
            CupertinoIcons.person_alt,
            size: size * 0.52,
            color: p.onPrimaryFill,
          ),
        ),
      ),
    );
  }
}

/// Buddy's answer (docs/DESIGN.md §8): no bubble — avatar + "Buddy", then
/// ONE clean card with the 4 sections (small bold labels), the law as pill +
/// short excerpt, steps as a numbered list; disclaimer underneath.
///
/// "Natural typing": typing dots for at least [minTypingDots], then the text
/// appears word by word ([revealWordsPerSecond]) with a soft caret; each
/// section card fades/slides in when its text starts. Tap → whole answer at
/// once. Reduce motion → no animation, text shows as it arrives.
class BuddyAnswer extends StatefulWidget {
  const BuddyAnswer({
    super.key,
    required this.message,
    this.stopSignal,
    this.onRevealing,
    this.onGrow,
  });

  final ChatMessage message;

  /// Fires when the driver taps Stop: the reveal freezes where it is.
  final Listenable? stopSignal;

  /// true while words are still being revealed (keep the Stop button).
  final ValueChanged<bool>? onRevealing;

  /// The answer got taller (for smooth auto-scroll).
  final VoidCallback? onGrow;

  @override
  State<BuddyAnswer> createState() => _BuddyAnswerState();
}

class _BuddyAnswerState extends State<BuddyAnswer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Reveal running (false: history, reduce motion, or finished).
  bool _animating = false;

  /// Tapped: show everything as soon as it arrives.
  bool _instant = false;

  /// Stop tapped mid-reveal.
  bool _frozen = false;

  double _shown = 0;
  Duration _elapsed = Duration.zero;
  Duration _last = Duration.zero;
  List<String> _units = const [];
  String _unitsFor = '';
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.stopSignal?.addListener(_freeze);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      // Only a fresh answer types itself out; history shows at once.
      if (widget.message.streaming && !_reduceMotion) {
        _animating = true;
        _ticker.start();
        _report(true);
      }
    } else if (_reduceMotion && _animating) {
      _finish();
    }
  }

  @override
  void didUpdateWidget(BuddyAnswer old) {
    super.didUpdateWidget(old);
    if (old.stopSignal != widget.stopSignal) {
      old.stopSignal?.removeListener(_freeze);
      widget.stopSignal?.addListener(_freeze);
    }
  }

  @override
  void dispose() {
    widget.stopSignal?.removeListener(_freeze);
    if (_animating) _report(false);
    _ticker.dispose();
    super.dispose();
  }

  List<String> _unitsOf(ChatMessage m) {
    if (m.text != _unitsFor) {
      _unitsFor = m.text;
      _units = revealUnits(m.text, streaming: m.streaming);
    }
    return _units;
  }

  void _tick(Duration elapsed) {
    // Only time after the minimum dots counts toward the reveal.
    final from = _last > minTypingDots ? _last : minTypingDots;
    final dt = elapsed > from ? elapsed - from : Duration.zero;
    _last = elapsed;
    _elapsed = elapsed;
    final units = _unitsOf(widget.message);
    final before = _shown.floor();
    if (_instant) {
      _shown = units.length.toDouble();
    } else if (elapsed >= minTypingDots && units.isNotEmpty) {
      _shown = math.min(
        _shown + dt.inMicroseconds * revealWordsPerSecond / 1e6,
        units.length.toDouble(),
      );
    }
    final done =
        !widget.message.streaming &&
        _shown >= units.length &&
        (elapsed >= minTypingDots || _instant);
    if (done) {
      _finish();
      return;
    }
    setState(() {}); // also blinks the caret
    if (_shown.floor() != before) _grew();
  }

  void _finish() {
    _ticker.stop();
    _report(false);
    setState(() => _animating = false);
    _grew();
  }

  void _freeze() {
    if (!_animating) return;
    _frozen = true;
    _finish();
  }

  void _completeNow() {
    if (!_animating) return;
    setState(() => _instant = true);
  }

  void _report(bool revealing) {
    final cb = widget.onRevealing;
    if (cb == null) return;
    // Never notify the parent in the middle of a build.
    SchedulerBinding.instance.addPostFrameCallback((_) => cb(revealing));
  }

  void _grew() {
    final cb = widget.onGrow;
    if (cb != null) SchedulerBinding.instance.addPostFrameCallback((_) => cb());
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final p = context.palette;
    final units = _unitsOf(m);

    // What is on screen right now.
    final String text;
    if (_animating || _frozen) {
      text = units.take(_shown.floor()).join();
    } else {
      text = m.text;
    }
    final dots =
        (_animating &&
            (_elapsed < minTypingDots || text.isEmpty) &&
            !_instant) ||
        (!_animating && m.streaming && m.text.trim().isEmpty);
    final caretOn =
        _animating && !dots && (_elapsed.inMilliseconds ~/ 530).isEven;
    final caret = _animating && !dots
        ? context.colors.primary.withValues(alpha: caretOn ? 0.9 : 0.15)
        : null;
    final parsed = parseAnswer(text);
    final settled = !_animating && !m.streaming;

    return GestureDetector(
      key: const Key('buddy-answer'),
      behavior: HitTestBehavior.translucent,
      onTap: _animating ? _completeNow : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const BuddyAvatar(size: 30),
              const SizedBox(width: AppSpace.xs),
              Text('Buddy', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          if (dots)
            const TypingIndicator()
          else
            // The whole answer is ONE clean card; sections are separated
            // by whitespace and small bold labels.
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md + 2,
                AppSpace.md,
                AppSpace.md + 2,
                AppSpace.md + 2,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: p.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (parsed.intro.isNotEmpty)
                    CitationText(
                      parsed.intro,
                      caretColor: parsed.hasSections ? null : caret,
                      animate: _animating,
                    ),
                  for (final (i, s) in parsed.sections.indexed)
                    _Entrance(
                      key: Key('section-${s.kind.name}'),
                      animate: _animating,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 && parsed.intro.isEmpty
                              ? 0
                              : AppSpace.md + 2,
                        ),
                        child: _Section(
                          kind: s.kind,
                          body: s.body,
                          caret: i == parsed.sections.length - 1 ? caret : null,
                          animate: _animating,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (m.stopped || _frozen)
            const _Note('Itinigil.', icon: CupertinoIcons.stop_circle),
          if (m.failed && !_animating)
            _Note(
              'Hindi nakasagot si Buddy. Subukan ulit.',
              icon: CupertinoIcons.exclamationmark_circle,
              color: p.cautionText,
            ),
          if (settled || _frozen)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs, left: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      CupertinoIcons.info_circle,
                      size: AppIcon.sm,
                      color: p.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      answerDisclaimer,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Fade + small slide up when a section starts (once).
class _Entrance extends StatelessWidget {
  const _Entrance({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// One section: small bold label + body. "Batas" shows the law excerpt,
/// "Gagawin" a numbered list.
class _Section extends StatelessWidget {
  const _Section({
    required this.kind,
    required this.body,
    required this.caret,
    required this.animate,
  });

  final AnswerSectionKind kind;
  final String body;
  final Color? caret;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kind.label,
          style: context.text.labelLarge?.copyWith(
            color: _labelColor(context, kind),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpace.xxs + 2),
        switch (kind) {
          AnswerSectionKind.batas => _LawExcerpt(
            body: body,
            caret: caret,
            animate: animate,
          ),
          AnswerSectionKind.gagawin => _Steps(
            body: body,
            caret: caret,
            animate: animate,
          ),
          _ => CitationText(body, caretColor: caret, animate: animate),
        },
      ],
    );
  }
}

/// Citation pill(s) + the first 2 lines of the law text (from laws.json)
/// + "Basahin ang buong batas" → bottom sheet. No long quotes inline.
/// Falls back to the plain text when the law isn't in laws.json.
class _LawExcerpt extends ConsumerWidget {
  const _LawExcerpt({
    required this.body,
    required this.caret,
    required this.animate,
  });

  final String body;
  final Color? caret;
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laws = ref.watch(lawSectionsProvider).valueOrNull;
    final cites = {
      for (final m in citationPattern.allMatches(body)) m.group(0)!,
    }.toList();
    String? mainCite;
    LawSection? law;
    for (final c in cites) {
      final id = lawIdFor(c);
      final l = id == null ? null : laws?[id];
      if (l != null) {
        mainCite = c;
        law = l;
        break;
      }
    }
    if (law == null || mainCite == null) {
      return CitationText(body, caretColor: caret, animate: animate);
    }
    final cite = mainCite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xxs,
          children: [
            for (final c in cites)
              _Entrance(
                key: ValueKey('citation-$c'),
                animate: animate,
                child: LawPill(c, onTap: () => showLawSheet(context, c)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          law.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
          key: const Key('law-excerpt'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            color: context.palette.muted,
            height: 1.45,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            key: const Key('read-law'),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            minimumSize: const Size(44, 44),
            onPressed: () => showLawSheet(context, cite),
            child: Text(
              'Basahin ang buong batas',
              style: context.text.titleSmall?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Ano ang gagawin" as a short numbered list.
class _Steps extends StatelessWidget {
  const _Steps({
    required this.body,
    required this.caret,
    required this.animate,
  });

  final String body;
  final Color? caret;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final lines = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final step = RegExp(r'^(\d+)[.)]\s*(.*)$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, line) in lines.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs),
            child: switch (step.firstMatch(line)) {
              final m? => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2, right: AppSpace.sm),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.palette.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.2,
                      child: Text(
                        m.group(1)!,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CitationText(
                      m.group(2)!,
                      caretColor: i == lines.length - 1 ? caret : null,
                      animate: animate,
                    ),
                  ),
                ],
              ),
              _ => CitationText(
                line,
                caretColor: i == lines.length - 1 ? caret : null,
                animate: animate,
              ),
            },
          ),
      ],
    );
  }
}

/// Body text with legal citations as tappable law pills (→ full law text).
class CitationText extends StatelessWidget {
  const CitationText(
    this.data, {
    super.key,
    this.caretColor,
    this.animate = false,
  });

  final String data;

  /// Typing caret at the end (null = none).
  final Color? caretColor;

  /// Pills fade in (while Buddy is typing).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyLarge?.copyWith(height: 1.45);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in citationPattern.allMatches(data)) {
      if (m.start > last) {
        spans.add(TextSpan(text: data.substring(last, m.start)));
      }
      final cite = m.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Entrance(
            key: ValueKey('citation-$cite'),
            animate: animate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: LawPill(cite, onTap: () => showLawSheet(context, cite)),
            ),
          ),
        ),
      );
      last = m.end;
    }
    if (last < data.length) spans.add(TextSpan(text: data.substring(last)));
    if (caretColor != null) {
      spans.add(
        TextSpan(
          text: ' ▍',
          style: TextStyle(color: caretColor),
          semanticsLabel: '',
        ),
      );
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

/// Three dots bouncing in turn (static under reduce motion), with the words
/// for screen readers and for drivers who glance.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.typing,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: 'Nag-iisip si Buddy',
      excludeSemantics: true,
      child: Row(
        key: const Key('typing-dots'),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.elevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < 3; i++) _dot(context, i)],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text('Nag-iisip si Buddy…', style: context.text.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context, int i) {
    // Each dot rises in turn: a sine bump shifted by a third of the cycle.
    final t = (_c.value - i / 3) % 1.0;
    final bump = t < 0.5 ? math.sin(t * 2 * math.pi) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Transform.translate(
        offset: Offset(0, -3 * bump),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.palette.muted.withValues(alpha: 0.5 + 0.5 * bump),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.icon, this.color});

  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.muted;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs, left: 2),
      child: Row(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(color: c),
            ),
          ),
        ],
      ),
    );
  }
}
