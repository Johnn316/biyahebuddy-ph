import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../../shared/widgets/scale_down_to_fit.dart';
import '../controllers/violation_controller.dart';

IconData _icon(Agency a) => switch (a) {
  Agency.lto => CupertinoIcons.person_crop_rectangle_fill,
  Agency.mmda => CupertinoIcons.car_detailed,
  Agency.city => CupertinoIcons.building_2_fill,
};

/// Step 1: large title + one grouped card of three tall rows that fills
/// the screen.
class AgencyPickerLarge extends StatelessWidget {
  const AgencyPickerLarge({super.key, required this.onSelected});

  final ValueChanged<Agency> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LargeTitle('Na-flag ako', subtitle: "Sino ang nag-flag sa'yo?"),
          const SizedBox(height: 18),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                boxShadow: context.palette.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, a) in Agency.values.indexed) ...[
                        if (i > 0) const Divider(indent: 88),
                        Expanded(
                          child: InkWell(
                            key: Key('agency-${a.name}'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelected(a);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: ScaleDownToFit(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    IconSquare(
                                      _icon(a),
                                      color: context.colors.primary,
                                      size: 54,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.label,
                                            style: context.text.headlineLarge,
                                          ),
                                          Text(
                                            a.description,
                                            style: context.text.bodySmall,
                                          ),
                                          _AgencyCount(agency: a),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_forward,
                                      color: context.palette.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 header: iOS segmented control so the agency can still be changed.
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
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<Agency>(
        groupValue: selected,
        thumbColor: context.colors.surface,
        backgroundColor: context.palette.elevated,
        padding: const EdgeInsets.all(4),
        children: {
          for (final a in Agency.values)
            a: Semantics(
              selected: a == selected,
              button: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    a.label,
                    key: Key('agency-chip-${a.name}'),
                    style: context.text.titleSmall,
                  ),
                ),
              ),
            ),
        },
        onValueChanged: (a) {
          if (a == null) return;
          HapticFeedback.selectionClick();
          onSelected(a);
        },
      ),
    );
  }
}

/// "24 na violation" under an agency (empty while loading).
class _AgencyCount extends ConsumerWidget {
  const _AgencyCount({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(agencyCountProvider(agency)).valueOrNull;
    return Text(
      n == null ? ' ' : '$n na violation',
      key: Key('agency-count-${agency.name}'),
      style: context.text.labelMedium?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
