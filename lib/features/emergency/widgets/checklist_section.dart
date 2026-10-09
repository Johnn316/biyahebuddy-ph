import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// "Ano ang gagawin ngayon" — tickable steps after a crash.
class ChecklistSection extends ConsumerWidget {
  const ChecklistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(checklistProvider);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Ano ang gagawin ngayon',
          trailing: Text(
            '${done.length}/${emergencyChecklist.length}',
            style: text.titleLarge?.copyWith(
              color: done.length == emergencyChecklist.length
                  ? AppColors.ok
                  : Colors.white70,
            ),
          ),
        ),
        for (final (i, item) in emergencyChecklist.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              key: Key('check-$i'),
              value: done.contains(i),
              onChanged: (v) => ref.read(checklistProvider.notifier).state = {
                ...done.where((d) => d != i),
                if (v ?? false) i,
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              title: Text(
                item,
                style: text.titleLarge?.copyWith(
                  decoration: done.contains(i)
                      ? TextDecoration.lineThrough
                      : null,
                  color: done.contains(i) ? Colors.white60 : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
