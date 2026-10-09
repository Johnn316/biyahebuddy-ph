import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// Nationwide hotlines; each row is one tap → dialer.
class HotlinesSection extends ConsumerWidget {
  const HotlinesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotlines = ref.watch(emergencyHotlinesProvider);
    final p = context.palette;
    final canCall =
        ref.watch(sosCapabilitiesProvider).valueOrNull?.call ?? true;

    return GroupedSection(
      header: 'Hotlines',
      footer: canCall
          ? null
          : 'Hindi makatawag ang device na ito (walang SIM?). '
                'Gumagana pa rin ang 911.',
      separatorIndent: 66,
      children: hotlines.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(20),
            child: CupertinoActivityIndicator(),
          ),
        ],
        error: (_, _) => [
          const GroupedTile(
            title: 'Hindi ma-load ang hotlines. I-dial ang 911.',
          ),
        ],
        data: (list) => [
          for (final h in list)
            Builder(
              builder: (context) {
                // 911 works without a SIM, so it's never greyed out.
                final enabled = canCall || alwaysCallable.contains(h.number);
                return Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: GroupedTile(
                    tapKey: Key('hotline-${h.number}'),
                    leading: IconSquare(
                      CupertinoIcons.phone_fill,
                      color: enabled ? p.success : p.elevated,
                    ),
                    title: h.number,
                    titleStyle: context.text.headlineSmall,
                    subtitle: h.name,
                    chevron: false,
                    trailing: Text(
                      'Tawagan',
                      style: context.text.titleSmall?.copyWith(
                        color: enabled ? context.colors.primary : p.muted,
                      ),
                    ),
                    onTap: enabled
                        ? () => dialNumber(context, ref, h.number)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
