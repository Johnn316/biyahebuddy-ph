import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';

/// Compact iOS-style pill: amber "Coding ka ngayon" / green "Hindi ka coding".
/// Never red: red is reserved for SOS.
class CodingPill extends StatelessWidget {
  const CodingPill({super.key, required this.coding});

  /// null while loading / no profile.
  final CodingStatus? coding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, bg, fg, icon) = switch (coding) {
      CodingStatus(isCoding: true) => (
        'Coding ka ngayon',
        p.accent,
        p.onAccent,
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      CodingStatus() => (
        'Hindi ka coding',
        p.success,
        p.onSuccess,
        CupertinoIcons.checkmark_seal_fill,
      ),
      null => ('Tinitingnan…', p.elevated, context.colors.onSurface, null),
    };
    return Semantics(
      label: 'MMDA coding. $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('MMDA coding', style: context.text.bodySmall),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              key: const Key('coding-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded pill action under the SOS button.
class PillAction extends StatelessWidget {
  const PillAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    return Pressable(
      child: Material(
        color: context.colors.surface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // One line, shrinks to fit half the width on narrow phones.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: c),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      maxLines: 1,
                      style: context.text.titleSmall?.copyWith(color: c),
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
