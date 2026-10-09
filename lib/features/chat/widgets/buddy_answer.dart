import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/answer_format.dart';
import '../controllers/chat_controller.dart';

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
    color: context.palette.accent,
  ),
  AnswerSectionKind.pagsusuri => (
    icon: CupertinoIcons.search,
    color: context.colors.primary,
  ),
  AnswerSectionKind.gagawin => (
    icon: CupertinoIcons.list_bullet,
    color: context.colors.primary,
  ),
};

/// Buddy avatar: round blue circle with a soft ring.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary.withValues(alpha: 0.85), scheme.primary],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_alt,
        size: size * 0.58,
        color: scheme.onPrimary,
      ),
    );
  }
}

/// Buddy's answer: gray bubble (left, with avatar) holding the 4 sections as
/// inset cards when present, else plain text. Citations are amber pills.
/// Disclaimer always underneath.
class BuddyAnswer extends StatelessWidget {
  const BuddyAnswer({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final parsed = parseAnswer(message.text);
    final waiting = message.streaming && message.text.trim().isEmpty;
    final p = context.palette;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const BuddyAvatar(),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: p.elevated,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text('Buddy', style: context.text.titleSmall),
                        ),
                        if (waiting)
                          const _Thinking()
                        else ...[
                          if (parsed.intro.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                              child: CitationText(
                                parsed.intro +
                                    (parsed.hasSections ? '' : _cursor),
                              ),
                            ),
                          for (final (i, s) in parsed.sections.indexed)
                            _SectionCard(
                              key: Key('section-${s.kind.name}'),
                              label: s.kind.label,
                              icon: _style(context, s.kind).icon,
                              color: _style(context, s.kind).color,
                              child: CitationText(
                                s.body +
                                    (i == parsed.sections.length - 1
                                        ? _cursor
                                        : ''),
                              ),
                            ),
                        ],
                        if (message.stopped)
                          const _Note(
                            'Itinigil.',
                            icon: CupertinoIcons.stop_circle,
                          ),
                        if (message.failed)
                          _Note(
                            'Hindi nakasagot si Buddy. Subukan ulit.',
                            icon: CupertinoIcons.exclamationmark_circle,
                            color: p.accent,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 46),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 15, color: p.muted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      answerDisclaimer,
                      style: context.text.bodySmall?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _cursor => message.streaming ? ' ▍' : '';
}

/// Clean inset card for one answer section.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: context.text.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Body text with legal citations rendered as amber pills.
class CitationText extends StatelessWidget {
  const CitationText(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyLarge;
    final p = context.palette;
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
          child: Container(
            key: ValueKey('citation-$cite'),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.book_fill, size: 14, color: p.onAccent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    cite,
                    style: style?.copyWith(
                      color: p.onAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: (style.fontSize ?? 18) - 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      last = m.end;
    }
    if (last < data.length) spans.add(TextSpan(text: data.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 10),
          Flexible(
            child: Text('Nag-iisip si Buddy…', style: context.text.bodyLarge),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 8, left: 4),
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
