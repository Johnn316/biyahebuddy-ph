import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../controllers/emergency_controller.dart';

/// "Ano ang gagawin ngayon" — tickable steps after a crash.
class ChecklistSection extends ConsumerWidget {
  const ChecklistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(checklistProvider);
    final p = context.palette;
    final allDone = done.length == emergencyChecklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Ano ang gagawin ngayon',
          icon: Icons.checklist_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: allDone ? p.success : context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${done.length}/${emergencyChecklist.length}',
              style: context.text.titleMedium?.copyWith(
                color: allDone ? p.onSuccess : p.muted,
              ),
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final (i, item) in emergencyChecklist.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                CheckboxListTile(
                  key: Key('check-$i'),
                  value: done.contains(i),
                  onChanged: (v) => ref.read(checklistProvider.notifier).state =
                      {...done.where((d) => d != i), if (v ?? false) i},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  title: Text(
                    item,
                    style: context.text.titleMedium?.copyWith(
                      decoration: done.contains(i)
                          ? TextDecoration.lineThrough
                          : null,
                      color: done.contains(i) ? p.muted : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
