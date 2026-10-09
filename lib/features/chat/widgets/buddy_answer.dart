import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/answer_format.dart';
import '../controllers/chat_controller.dart';

const answerDisclaimer = 'Gabay batay sa batas, hindi legal na hatol.';

({IconData icon, Color color}) _style(AnswerSectionKind k) => switch (k) {
  AnswerSectionKind.kalma => (
    icon: Icons.self_improvement,
    color: AppColors.ok,
  ),
  AnswerSectionKind.batas => (icon: Icons.gavel, color: AppColors.accent),
  AnswerSectionKind.pagsusuri => (
    icon: Icons.search,
    color: Colors.lightBlueAccent,
  ),
  AnswerSectionKind.gagawin => (icon: Icons.checklist, color: Colors.white),
};

/// Buddy's answer: 4 labeled sections when present, else plain text.
/// Citations are shown as amber chips. Disclaimer always underneath.
class BuddyAnswer extends StatelessWidget {
  const BuddyAnswer({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final parsed = parseAnswer(message.text);
    final waiting = message.streaming && message.text.trim().isEmpty;

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
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.support_agent, size: 20),
                ),
                const SizedBox(width: 8),
                Text('Buddy', style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 6),
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
                  icon: _style(s.kind).icon,
                  color: _style(s.kind).color,
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
                icon: Icons.error_outline,
                color: AppColors.warning,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                answerDisclaimer,
                style: text.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
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
    this.color = Colors.white24,
  });

  final Widget child;
  final String? label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label!,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
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
    final style = Theme.of(context).textTheme.bodyLarge;
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, size: 16, color: Colors.black),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cite,
                    style: style?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
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
    return const _SectionCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text('Nag-iisip si Buddy…', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.icon, this.color = Colors.white70});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
