import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'pressable.dart';

/// Rounded borderless surface (iOS card). Tappable (light haptic + press
/// scale) when [onTap] is set. Pass [color]/[gradient] for colored cards.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSizes.gap),
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = AppSizes.radius,
    this.shadow = true,
    this.tapKey,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  /// Key for the tappable InkWell (for tests).
  final Key? tapKey;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.colors.surface) : null,
        gradient: gradient,
        borderRadius: shape,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
        boxShadow: shadow ? context.palette.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: tapKey,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    final result = onTap == null ? card : Pressable(child: card);
    return margin == null ? result : Padding(padding: margin!, child: result);
  }
}
