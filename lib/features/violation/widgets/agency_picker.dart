import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/scale_down_to_fit.dart';
import '../controllers/violation_controller.dart';

IconData _icon(Agency a) => switch (a) {
  Agency.lto => Icons.badge_rounded,
  Agency.mmda => Icons.traffic_rounded,
  Agency.city => Icons.location_city_rounded,
};

/// Step 1: three big cards that fill the screen.
class AgencyPickerLarge extends StatelessWidget {
  const AgencyPickerLarge({super.key, required this.onSelected});

  final ValueChanged<Agency> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Sino ang nag-flag sa'yo?", style: context.text.headlineLarge),
          for (final a in Agency.values) ...[
            const SizedBox(height: AppSizes.gap),
            Expanded(
              child: AppCard(
                tapKey: Key('agency-${a.name}'),
                onTap: () => onSelected(a),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: ScaleDownToFit(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Icon(_icon(a), size: 44, color: primary),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label, style: context.text.displaySmall),
                            Text(
                              a.description,
                              style: context.text.bodyMedium?.copyWith(
                                color: context.palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 36,
                        color: context.palette.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Step 2 header: compact switcher so the agency can still be changed.
class AgencyPickerCompact extends StatelessWidget {
  const AgencyPickerCompact({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Agency selected;
  final ValueChanged<Agency> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Row(
      children: [
        for (final (i, a) in Agency.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: a == selected,
              button: true,
              child: Pressable(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: a == selected ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: a == selected ? scheme.primary : scheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('agency-chip-${a.name}'),
                      onTap: () => onSelected(a),
                      child: SizedBox(
                        height: 56,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                a.label,
                                style: context.text.titleMedium?.copyWith(
                                  color: a == selected
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
