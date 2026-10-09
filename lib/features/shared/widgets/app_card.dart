import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'pressable.dart';

/// Rounded surface with a soft shadow. Tappable (ripple + press scale) when
/// [onTap] is set. Pass [color]/[gradient] for colored hero cards.
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
            ? (color == null && gradient == null
                  ? Border.all(color: context.colors.outline)
                  : null)
            : Border.all(color: borderColor!, width: 2),
        boxShadow: shadow ? context.palette.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: tapKey,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    final result = onTap == null ? card : Pressable(child: card);
    return margin == null ? result : Padding(padding: margin!, child: result);
  }
}

/// Section heading used inside long screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.icon, this.trailing});

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 26, color: context.colors.primary),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title, style: context.text.headlineSmall)),
          ?trailing,
        ],
      ),
    );
  }
}
