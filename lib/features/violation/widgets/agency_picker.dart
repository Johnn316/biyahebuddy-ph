import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/violation_controller.dart';

IconData _icon(Agency a) => switch (a) {
  Agency.lto => Icons.badge,
  Agency.mmda => Icons.traffic,
  Agency.city => Icons.location_city,
};

/// Step 1: three huge tiles that fill the screen.
class AgencyPickerLarge extends StatelessWidget {
  const AgencyPickerLarge({super.key, required this.onSelected});

  final ValueChanged<Agency> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Sino ang nag-flag sa'yo?", style: text.headlineMedium),
          for (final a in Agency.values) ...[
            const SizedBox(height: AppSizes.gap),
            Expanded(
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  side: const BorderSide(color: AppColors.accent, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('agency-${a.name}'),
                  onTap: () => onSelected(a),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(_icon(a), size: 56, color: AppColors.accent),
                        const SizedBox(width: 20),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.label, style: text.displayLarge),
                                Text(a.description, style: text.bodyLarge),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 40),
                      ],
                    ),
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
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final (i, a) in Agency.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: a == selected,
              button: true,
              child: Material(
                color: a == selected ? AppColors.accent : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.accent, width: 2),
                ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            a.label,
                            style: text.titleLarge?.copyWith(
                              color: a == selected
                                  ? Colors.black
                                  : Colors.white,
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
