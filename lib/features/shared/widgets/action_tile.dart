import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'pressable.dart';

/// Quick-action tile for the Home grid (docs/DESIGN.md §8 "Action tile").
/// Regular: tinted icon square on top, title, one-line subtitle.
/// Compact (short screens): icon + title in one row.
/// The whole tile is one button: press scale 0.97 + light haptic.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.subtitle,
    this.compact = false,
    this.tapKey,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool compact;

  /// Key on the tappable surface (tests and deep links).
  final Key? tapKey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);
    final iconSquare = Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: compact ? 20 : 24, color: iconColor),
    );
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.text.titleMedium,
    );

    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
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
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm + 2),
                child: compact
                    ? Row(
                        children: [
                          iconSquare,
                          const SizedBox(width: AppSpace.sm),
                          Expanded(child: titleText),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconSquare,
                          const SizedBox(height: AppSpace.sm),
                          titleText,
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: p.muted,
                                fontSize: 13,
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
