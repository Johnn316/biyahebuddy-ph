import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// "Ligtas ka ba?" + (if injured) a big "Tumawag sa 911" button.
class SafetyCheck extends ConsumerWidget {
  const SafetyCheck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injured = ref.watch(injuredProvider);
    final text = Theme.of(context).textTheme;

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
          child: selected
              ? FilledButton.icon(
                  key: key,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: onColor,
                    minimumSize: const Size.fromHeight(72),
                  ),
                  onPressed: () =>
                      ref.read(injuredProvider.notifier).state = value,
                  icon: Icon(icon),
                  label: FittedBox(child: Text(label)),
                )
              : OutlinedButton.icon(
                  key: key,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: color, width: 3),
                    minimumSize: const Size.fromHeight(72),
                    textStyle: text.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                  ),
                  onPressed: () =>
                      ref.read(injuredProvider.notifier).state = value,
                  icon: Icon(icon),
                  label: FittedBox(child: Text(label)),
                ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ligtas ka ba?', style: text.displayLarge?.copyWith(fontSize: 36)),
        const SizedBox(height: 12),
        Row(
          children: [
            choice(
              key: const Key('injured-yes'),
              label: 'May sugatan',
              icon: Icons.personal_injury,
              value: true,
              color: AppColors.emergency,
              onColor: Colors.white,
            ),
            const SizedBox(width: 12),
            choice(
              key: const Key('injured-no'),
              label: 'Walang sugatan',
              icon: Icons.health_and_safety,
              value: false,
              color: AppColors.ok,
              onColor: Colors.black,
            ),
          ],
        ),
        if (injured == true) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('call-911'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(96),
              textStyle: text.displayLarge?.copyWith(fontSize: 32),
              side: const BorderSide(color: Colors.white, width: 3),
            ),
            onPressed: () => dialNumber(context, ref, '911'),
            icon: const Icon(Icons.call, size: 40),
            label: const Text('Tumawag sa 911'),
          ),
        ],
      ],
    );
  }
}
