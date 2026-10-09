import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';

/// What a chip means — picks its colors (never red: red is SOS-only).
enum ChipTone { success, caution, info, neutral }

/// Compact fact pill (docs/DESIGN.md §8 "Status chip"): filled icon + label
/// on a tinted background. Color is never the only signal — the icon and
/// the words carry the meaning too. Text growth is capped at 1.3×.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    this.height = 36,
    this.semanticsLabel,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      ChipTone.success => (p.successTint, p.success),
      ChipTone.caution => (p.cautionTint, p.cautionText),
      ChipTone.info => (p.primaryTint, context.colors.primary),
      ChipTone.neutral => (p.elevated, p.muted),
    };
    return Semantics(
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.enter,
          constraints: BoxConstraints(minHeight: height),
          padding: EdgeInsets.symmetric(
            horizontal: height >= 36 ? AppSpace.sm : AppSpace.xs + 2,
            vertical: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: height >= 36 ? 18 : AppIcon.sm, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Offline-ready ✓" trust badge: Buddy's AI runs on the phone.
/// ready → green; missing → amber "I-download si Buddy".
class OfflineReadyBadge extends StatelessWidget {
  const OfflineReadyBadge({
    super.key,
    required this.ready,
    this.compact = false,
  });

  final bool ready;

  /// Header size (28dp) instead of chip size (36dp).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      key: const Key('offline-badge'),
      height: compact ? 28 : 36,
      tone: ready ? ChipTone.success : ChipTone.caution,
      icon: ready
          ? CupertinoIcons.checkmark_seal_fill
          : CupertinoIcons.arrow_down_circle_fill,
      label: ready ? 'Offline-ready' : 'I-download si Buddy',
      semanticsLabel: ready
          ? 'Offline-ready. Gumagana si Buddy kahit walang signal.'
          : 'Hindi pa naka-download si Buddy.',
    );
  }
}
