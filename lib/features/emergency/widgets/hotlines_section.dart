import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// Nationwide hotlines; each row is one tap → dialer.
class HotlinesSection extends ConsumerWidget {
  const HotlinesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotlines = ref.watch(emergencyHotlinesProvider);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Hotlines'),
        ...hotlines.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            Text(
              'Hindi ma-load ang hotlines. I-dial ang 911.',
              style: text.titleLarge,
            ),
          ],
          data: (list) => [
            for (final h in list)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('hotline-${h.number}'),
                  onTap: () => dialNumber(context, ref, h.number),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name, style: text.bodyLarge),
                                Text(
                                  h.number,
                                  style: text.headlineMedium?.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.call, color: AppColors.ok, size: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
