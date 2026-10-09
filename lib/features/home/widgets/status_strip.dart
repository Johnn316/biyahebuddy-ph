import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../controllers/home_controller.dart';

/// Plate + MMDA coding status. Amber = coding now, green = not coding.
/// Never red: red is reserved for EMERGENCY.
class StatusStrip extends ConsumerWidget {
  const StatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider);
    final p = context.palette;
    final muted = context.colors.surfaceContainerHighest;

    // valueOrNull keeps the last value visible while the minute tick reloads.
    final s = status.valueOrNull;
    final (plate, badge, detail, color, onColor) = switch ((
      s,
      status.hasError,
    )) {
      (final s?, _) when s.coding.isCoding => (
        s.plateNo,
        'Coding ka ngayon',
        s.coding.message,
        p.accent,
        p.onAccent,
      ),
      (final s?, _) => (
        s.plateNo,
        'Hindi ka coding',
        s.coding.message,
        p.success,
        p.onSuccess,
      ),
      (null, true) => ('—', 'Hindi ma-check', null, p.accent, p.onAccent),
      _ when status.isLoading => (
        '…',
        'Tinitingnan…',
        null,
        muted,
        context.colors.onSurface,
      ),
      _ => ('—', 'Walang profile', null, p.accent, p.onAccent),
    };

    // Strip text is already large; cap system font scaling so it can't grow
    // taller than the screen on small phones with the largest font setting.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Semantics(
        container: true,
        label: 'MMDA coding. Plate $plate. $badge.',
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.directions_car_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MMDA coding',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        plate,
                        style: context.text.headlineSmall?.copyWith(
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  key: const Key('coding-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(color: onColor),
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
