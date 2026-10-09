import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pressable.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// "Ligtas ka ba?" + (if injured) a big "Tumawag sa 911" button.
class SafetyCheck extends ConsumerWidget {
  const SafetyCheck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injured = ref.watch(injuredProvider);
    final p = context.palette;

    Widget choice({
      required Key key,
      required String label,
      required IconData icon,
      required bool value,
      required Color color,
      required Color onColor,
    }) {
      final selected = injured == value;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: Pressable(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: selected ? color : context.colors.surface,
                // iOS: borderless when idle, colored ring when chosen.
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected ? p.cardShadow : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: key,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(injuredProvider.notifier).state = value;
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: selected ? onColor : color),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: context.text.titleMedium?.copyWith(
                                color: selected
                                    ? onColor
                                    : context.colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ligtas ka ba?', style: context.text.displaySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            choice(
              key: const Key('injured-yes'),
              label: 'May sugatan',
              icon: CupertinoIcons.bandage_fill,
              value: true,
              color: p.emergency,
              onColor: p.onEmergency,
            ),
            const SizedBox(width: 12),
            choice(
              key: const Key('injured-no'),
              label: 'Walang sugatan',
              icon: CupertinoIcons.checkmark_shield_fill,
              value: false,
              color: p.success,
              onColor: p.onSuccess,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: injured == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppCard(
                    tapKey: const Key('call-911'),
                    gradient: p.emergencyGradient,
                    onTap: () => dialNumber(context, ref, '911'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.phone_fill,
                          size: 40,
                          color: p.onEmergency,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Tumawag sa 911',
                            style: context.text.headlineLarge?.copyWith(
                              color: p.onEmergency,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
