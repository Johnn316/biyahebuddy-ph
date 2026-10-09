import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/emergency_controller.dart';

/// "Ano ang gagawin ngayon" — tickable steps after a crash.
class ChecklistSection extends ConsumerWidget {
  const ChecklistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(checklistProvider);
    final p = context.palette;
    final allDone = done.length == emergencyChecklist.length;

    return GroupedSection(
      header: 'Ano ang gagawin ngayon',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: allDone ? p.success : p.elevated,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${done.length}/${emergencyChecklist.length}',
          style: context.text.labelMedium?.copyWith(
            color: allDone ? p.onSuccess : context.colors.onSurface,
          ),
        ),
      ),
      separatorIndent: 58,
      children: [
        for (final (i, item) in emergencyChecklist.indexed)
          Semantics(
            checked: done.contains(i),
            child: InkWell(
              key: Key('check-$i'),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = {...done};
                if (!next.remove(i)) next.add(i);
                ref.read(checklistProvider.notifier).state = next;
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        done.contains(i)
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        key: ValueKey(done.contains(i)),
                        size: 30,
                        color: done.contains(i) ? p.success : p.muted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
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
                ),
              ),
            ),
          ),
      ],
    );
  }
}
