import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';
import '../controllers/topics.dart';

/// Category tiles, 2 per row (1 when text is huge). Tap → its questions.
class TopicGrid extends StatelessWidget {
  const TopicGrid({super.key, required this.onTap, this.width});

  final ValueChanged<BuddyTopic> onTap;

  /// Available width, if known (else assumes a phone).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final w = width ?? MediaQuery.sizeOf(context).width - 2 * AppSpace.md;
    final perRow = (w - AppSpace.sm) / 2 < 140 * scale ? 1 : 2;
    final tiles = [
      for (final t in buddyTopics) _TopicTile(topic: t, onTap: () => onTap(t)),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += perRow) {
      if (i > 0) rows.add(const SizedBox(height: AppSpace.sm));
      rows.add(
        perRow == 1
            ? tiles[i]
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.onTap});

  final BuddyTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      label: '${topic.label}. ${topic.subtitle}',
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
              key: Key('topic-${topic.id}'),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: p.primaryTint,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          topic.icon,
                          size: 18,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          topic.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A topic's questions as tappable cards + "Bumalik sa mga topic".
class TopicQuestions extends StatelessWidget {
  const TopicQuestions({
    super.key,
    required this.topic,
    required this.onQuestion,
    required this.onBack,
  });

  final BuddyTopic topic;
  final ValueChanged<String> onQuestion;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, q) in topic.questions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('topic-q-$i'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onQuestion(q);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            q,
                            style: context.text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: AppIcon.sm,
                          color: p.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('topics-back'),
            onPressed: onBack,
            icon: const Icon(CupertinoIcons.chevron_back, size: 18),
            label: const Text('Bumalik sa mga topic'),
          ),
        ),
      ],
    );
  }
}

/// After an answer: the topic's other questions + "Lahat ng topic".
class TopicFollowUps extends StatelessWidget {
  const TopicFollowUps({
    super.key,
    required this.topic,
    required this.asked,
    required this.onQuestion,
    required this.onAll,
  });

  final BuddyTopic topic;

  /// The question just answered (left out).
  final String? asked;
  final ValueChanged<String> onQuestion;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final others = [
      for (final q in topic.questions)
        if (q != asked) q,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (others.isNotEmpty) ...[
          Text(
            'Iba pang tanong sa ${topic.label}',
            style: context.text.labelLarge?.copyWith(
              color: context.palette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final (i, q) in others.indexed)
                ActionChip(
                  key: Key('topic-more-$i'),
                  label: Text(q),
                  labelStyle: context.text.titleSmall?.copyWith(
                    color: context.colors.primary,
                  ),
                  backgroundColor: context.palette.primaryTint,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => onQuestion(q),
                ),
            ],
          ),
        ],
        TextButton.icon(
          key: const Key('topics-all'),
          onPressed: onAll,
          icon: const Icon(CupertinoIcons.square_grid_2x2, size: 18),
          label: const Text('Lahat ng topic'),
        ),
      ],
    );
  }
}
