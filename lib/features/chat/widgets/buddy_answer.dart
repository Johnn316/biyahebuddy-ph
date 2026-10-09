import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/answer_format.dart';
import '../controllers/chat_controller.dart';

const answerDisclaimer = 'Gabay batay sa batas, hindi legal na hatol.';

({IconData icon, Color color}) _style(
  BuildContext context,
  AnswerSectionKind k,
) => switch (k) {
  AnswerSectionKind.kalma => (
    icon: Icons.self_improvement_rounded,
    color: context.palette.success,
  ),
  AnswerSectionKind.batas => (
    icon: Icons.gavel_rounded,
    color: context.palette.accent,
  ),
  AnswerSectionKind.pagsusuri => (
    icon: Icons.manage_search_rounded,
    color: context.colors.primary,
  ),
  AnswerSectionKind.gagawin => (
    icon: Icons.checklist_rounded,
    color: context.colors.onSurface,
  ),
};

/// Buddy avatar: round, primary, with a soft ring.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Icon(
        Icons.support_agent_rounded,
        size: size * 0.6,
        color: scheme.onPrimary,
      ),
    );
  }
}

/// Buddy's answer: 4 labeled section cards when present, else plain text.
/// Citations are amber chips. Disclaimer always underneath.
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
      child: FractionallySizedBox(
        widthFactor: 0.94,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const BuddyAvatar(),
                const SizedBox(width: 10),
                Text('Buddy', style: context.text.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (waiting)
              const _Thinking()
            else ...[
              if (parsed.intro.isNotEmpty)
                _SectionCard(
                  child: CitationText(
                    parsed.intro + (parsed.hasSections ? '' : _cursor),
                  ),
                ),
              for (final (i, s) in parsed.sections.indexed)
                _SectionCard(
                  key: Key('section-${s.kind.name}'),
                  label: s.kind.label,
                  icon: _style(context, s.kind).icon,
                  color: _style(context, s.kind).color,
                  child: CitationText(
                    s.body + (i == parsed.sections.length - 1 ? _cursor : ''),
                  ),
                ),
            ],
            if (message.stopped)
              _Note('Itinigil.', icon: Icons.stop_circle_outlined),
            if (message.failed)
              _Note(
                'Hindi nakasagot si Buddy. Subukan ulit.',
                icon: Icons.error_outline_rounded,
                color: p.accent,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: p.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      answerDisclaimer,
                      style: context.text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.child,
    this.label,
    this.icon,
    this.color,
  });

  final Widget child;
  final String? label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final c = color ?? scheme.outline;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
        boxShadow: context.palette.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: c, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label!,
                              style: context.text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Body text with legal citations rendered as amber chips.
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
                Icon(Icons.menu_book_rounded, size: 16, color: p.onAccent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    cite,
                    style: style?.copyWith(
                      color: p.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: (style.fontSize ?? 18) - 2,
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
    return _SectionCard(
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 12),
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
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(icon, color: c, size: 20),
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
