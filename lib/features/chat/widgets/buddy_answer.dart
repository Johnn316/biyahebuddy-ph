import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/law_pill.dart';
import '../controllers/answer_format.dart';
import '../controllers/answer_reveal.dart';
import '../controllers/chat_controller.dart';
import 'law_sheet.dart';

const answerDisclaimer = 'Gabay batay sa batas, hindi legal na hatol.';

({IconData icon, Color color}) _style(
  BuildContext context,
  AnswerSectionKind k,
) => switch (k) {
  AnswerSectionKind.kalma => (
    icon: CupertinoIcons.heart_fill,
    color: context.palette.success,
  ),
  AnswerSectionKind.batas => (
    icon: CupertinoIcons.book_fill,
    color: context.palette.cautionText,
  ),
  AnswerSectionKind.pagsusuri => (
    icon: CupertinoIcons.search,
    color: context.colors.primary,
  ),
  AnswerSectionKind.gagawin => (
    icon: CupertinoIcons.list_number,
    color: context.colors.primary,
  ),
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
/// the answer full width with the 4 sections as cards, citations as
/// tappable law pills, disclaimer underneath.
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
          else ...[
            if (parsed.intro.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, AppSpace.xxs),
                child: CitationText(
                  parsed.intro,
                  caretColor: parsed.hasSections ? null : caret,
                  animate: _animating,
                ),
              ),
            for (final (i, s) in parsed.sections.indexed)
              _Entrance(
                key: Key('section-${s.kind.name}'),
                animate: _animating,
                child: _SectionCard(
                  label: s.kind.label,
                  icon: _style(context, s.kind).icon,
                  color: _style(context, s.kind).color,
                  child: CitationText(
                    s.body,
                    caretColor: i == parsed.sections.length - 1 ? caret : null,
                    animate: _animating,
                  ),
                ),
              ),
          ],
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

/// Clean card for one answer section with a small colored icon badge.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.label,
    required this.icon,
    required this.color,
  });

  final Widget child;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.xs),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: p.cardShadow,
        border: Border(top: BorderSide(color: p.highlight, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          child,
        ],
      ),
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
