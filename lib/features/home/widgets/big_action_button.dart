import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Full-size tappable tile that fills whatever space its parent gives it.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.subtitle,
    this.foreground = Colors.white,
    this.large = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: subtitle == null ? label : '$label. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            // Scales the whole block down on short screens instead of
            // overflowing; on tall screens the tile itself fills the space.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: large ? 110 : 56, color: foreground),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: (large ? text.displayLarge : text.headlineMedium)
                        ?.copyWith(color: foreground, height: 1.1),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(color: foreground),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
