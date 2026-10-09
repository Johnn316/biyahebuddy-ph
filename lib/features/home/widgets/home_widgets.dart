import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/law_pill.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/status_chip.dart';
import '../controllers/home_controller.dart';

/// Dashboard status chips: MMDA coding · Offline-ready · GPS.
/// [scroll] puts them in one swipeable row (short screens) instead of
/// wrapping.
class HomeStatusChips extends ConsumerWidget {
  const HomeStatusChips({super.key, required this.coding, this.scroll = false});

  /// null while loading / no profile.
  final CodingStatus? coding;
  final bool scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsReady = ref.watch(modelManagerProvider).isReady;
    final gps = ref.watch(locationReadyProvider);

    final chips = <Widget>[
      switch (coding) {
        CodingStatus(isCoding: true) => const StatusChip(
          key: Key('coding-badge'),
          tone: ChipTone.caution,
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          label: 'Coding ka ngayon',
          semanticsLabel: 'MMDA coding: Coding ka ngayon',
        ),
        CodingStatus() => const StatusChip(
          key: Key('coding-badge'),
          tone: ChipTone.success,
          icon: CupertinoIcons.checkmark_circle_fill,
          label: 'Hindi ka coding',
          semanticsLabel: 'MMDA coding: Hindi ka coding',
        ),
        null => const StatusChip(
          key: Key('coding-badge'),
          tone: ChipTone.neutral,
          icon: CupertinoIcons.car_detailed,
          label: 'Tinitingnan…',
        ),
      },
      OfflineReadyBadge(ready: modelsReady),
      switch (gps) {
        AsyncData(value: true) => const StatusChip(
          tone: ChipTone.info,
          icon: CupertinoIcons.location_fill,
          label: 'GPS handa',
        ),
        AsyncData() || AsyncError() => const StatusChip(
          tone: ChipTone.neutral,
          icon: CupertinoIcons.location_slash_fill,
          label: 'Walang GPS',
        ),
        _ => const StatusChip(
          tone: ChipTone.neutral,
          icon: CupertinoIcons.location,
          label: 'Hinahanap ang GPS…',
        ),
      },
    ];

    if (scroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final (i, c) in chips.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              c,
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: chips);
  }
}

/// "Tip ng araw": one law section from laws.json, with its law pill.
class TipOfDayCard extends StatelessWidget {
  const TipOfDayCard({super.key, required this.tip, required this.onTap});

  final LawTip tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: 'Tip ng araw: ${tip.title}. ${tip.citation}. Itanong kay Buddy.',
      excludeSemantics: true,
      child: Pressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: radius,
            boxShadow: p.cardShadow,
            border: Border(top: BorderSide(color: p.highlight, width: 0.5)),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('home-tip'),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb_fill,
                          size: AppIcon.sm,
                          color: p.cautionText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'TIP NG ARAW',
                            style: context.text.labelSmall?.copyWith(
                              color: p.cautionText,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        LawPill(tip.citation),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      tip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
