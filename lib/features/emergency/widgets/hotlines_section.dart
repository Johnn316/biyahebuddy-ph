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

    return GroupedSection(
      header: 'Hotlines',
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
            GroupedTile(
              tapKey: Key('hotline-${h.number}'),
              leading: IconSquare(CupertinoIcons.phone_fill, color: p.success),
              title: h.number,
              titleStyle: context.text.headlineSmall,
              subtitle: h.name,
              chevron: false,
              trailing: Text(
                'Tawagan',
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              onTap: () => dialNumber(context, ref, h.number),
            ),
        ],
      ),
    );
  }
}
