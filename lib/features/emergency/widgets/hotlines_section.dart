import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// Nationwide hotlines; each row is one tap → dialer.
class HotlinesSection extends ConsumerWidget {
  const HotlinesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotlines = ref.watch(emergencyHotlinesProvider);
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Hotlines', icon: Icons.support_agent_rounded),
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
              style: context.text.titleLarge,
            ),
          ],
          data: (list) => [
            for (final h in list)
              AppCard(
                tapKey: Key('hotline-${h.number}'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                onTap: () => dialNumber(context, ref, h.number),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: context.text.bodyMedium?.copyWith(
                              color: p.muted,
                            ),
                          ),
                          Text(h.number, style: context.text.headlineMedium),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.success.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.call_rounded, color: p.success),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
