import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';

/// Plate + MMDA coding status. Red = coding now, green = not coding.
class StatusStrip extends ConsumerWidget {
  const StatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider);
    final text = Theme.of(context).textTheme;

    // valueOrNull keeps the last value visible while the minute tick reloads.
    final s = status.valueOrNull;
    final (plate, badge, detail, color) = switch ((s, status.hasError)) {
      (final s?, _) when s.coding.isCoding => (
        s.plateNo,
        'Coding ka ngayon',
        s.coding.message,
        AppColors.emergency,
      ),
      (final s?, _) => (
        s.plateNo,
        'Hindi ka coding',
        s.coding.message,
        AppColors.ok,
      ),
      (null, true) => ('—', 'Hindi ma-check', null, AppColors.warning),
      _ when status.isLoading => ('…', 'Tinitingnan…', null, AppColors.surface),
      _ => ('—', 'Walang profile', null, AppColors.warning),
    };
    final onColor = color == AppColors.ok || color == AppColors.warning
        ? Colors.black
        : Colors.white;

    return Semantics(
      container: true,
      label: 'MMDA coding. Plate $plate. $badge.',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: color, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MMDA coding',
                        style: text.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          plate,
                          style: text.headlineMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail,
                          style: text.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 140,
                color: color,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(color: onColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
