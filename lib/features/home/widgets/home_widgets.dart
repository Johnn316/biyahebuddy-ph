import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/law_pill.dart';
import '../../shared/widgets/pressable.dart';
import '../controllers/home_controller.dart';

/// "Tip ng araw": one law section from laws.json, with its law pill.
class TipOfDayCard extends StatelessWidget {
  const TipOfDayCard({super.key, required this.tip, required this.onTap});

  final LawTip tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: 'Tip ng araw: ${tip.title}. ${tip.citation}. Itanong kay Buddy.',
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
              key: const Key('home-tip'),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb_fill,
                          size: AppIcon.sm,
                          color: p.cautionText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'TIP NG ARAW',
                            style: context.text.labelSmall?.copyWith(
                              color: p.cautionText,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        LawPill(tip.citation),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      tip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(color: p.muted),
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
