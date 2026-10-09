import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../shared/widgets/grouped.dart';

/// iOS Settings-style appearance: "Sundin ang system" switch; when off,
/// a Light / Dark segmented control. Saved in shared_preferences.
class ThemeModePicker extends ConsumerWidget {
  const ThemeModePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final controller = ref.read(themeModeProvider.notifier);
    final followSystem = mode == ThemeMode.system;

    return GroupedSection(
      header: 'Itsura',
      separatorIndent: 64,
      children: [
        GroupedTile(
          leading: IconSquare(
            CupertinoIcons.circle_lefthalf_fill,
            color: context.colors.primary,
          ),
          title: 'Sundin ang system',
          subtitle: 'Light o dark ayon sa phone',
          trailing: Switch.adaptive(
            key: const Key('theme-follow-system'),
            value: followSystem,
            onChanged: (on) {
              HapticFeedback.selectionClick();
              controller.set(
                on
                    ? ThemeMode.system
                    : (Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light),
              );
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: followSystem
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<ThemeMode>(
                      key: const Key('theme-mode'),
                      groupValue: mode,
                      thumbColor: context.colors.surface,
                      backgroundColor: context.palette.elevated,
                      padding: const EdgeInsets.all(4),
                      children: {
                        for (final (m, icon, label) in [
                          (
                            ThemeMode.light,
                            CupertinoIcons.sun_max_fill,
                            'Light',
                          ),
                          (ThemeMode.dark, CupertinoIcons.moon_fill, 'Dark'),
                        ])
                          m: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    label,
                                    style: context.text.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      },
                      onValueChanged: (m) {
                        if (m == null) return;
                        HapticFeedback.selectionClick();
                        controller.set(m);
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
