import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/status_chip.dart';
import '../controllers/home_controller.dart';

/// Home hero: who's driving, which car, and today's status.
/// Avatar + greeting + name · PH plate badge + vehicle · status chips in one
/// row. Tap → Profile.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key, required this.status, required this.onTap});

  /// null while loading / no profile.
  final HomeStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = status;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      label: s == null
          ? 'Profile'
          : '${s.greeting}, ${s.name}. Plate ${s.plateNo}, ${s.vehicleType}. '
                'Buksan ang profile.',
      child: Pressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: p.heroGradient,
            borderRadius: radius,
            boxShadow: p.raisedShadow,
            border: Border.all(color: p.highlight, width: 0.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('home-profile-card'),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _Avatar(name: s?.name ?? ''),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(child: _Identity(status: s)),
                        ExcludeSemantics(
                          child: Icon(
                            CupertinoIcons.chevron_forward,
                            size: AppIcon.md,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _ChipsRow(coding: s?.coding),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: p.ringGradient,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.surface,
          ),
          alignment: Alignment.center,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: context.text.titleLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.status});

  final HomeStatus? status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s?.greeting ?? 'Magandang araw',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
          // Name never cuts off: it shrinks to fit one line.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              s?.name ?? '—',
              maxLines: 1,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (s != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                PlateBadge(plate: s.plateNo),
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    s.vehicleType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// White PH-style license plate: dark bold spaced digits, thin border.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('plate-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: p.plateFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.plateBorder, width: 1.2),
        ),
        child: Text(
          plate.toUpperCase(),
          style: context.text.titleSmall?.copyWith(
            color: p.plateInk,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Coding · Offline · GPS (icon-only). Always one row: it shrinks slightly
/// at the largest text sizes instead of wrapping or cutting off.
class _ChipsRow extends ConsumerWidget {
  const _ChipsRow({required this.coding});

  final CodingStatus? coding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsReady = ref.watch(modelManagerProvider).isReady;
    final gps = ref.watch(locationReadyProvider);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (coding) {
            CodingStatus(isCoding: true) => const StatusChip(
              key: Key('coding-badge'),
              tone: ChipTone.caution,
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              label: 'Coding ngayon',
              semanticsLabel: 'MMDA coding: Coding ka ngayon',
            ),
            CodingStatus() => const StatusChip(
              key: Key('coding-badge'),
              tone: ChipTone.success,
              icon: CupertinoIcons.checkmark_circle_fill,
              label: 'Hindi coding',
              semanticsLabel: 'MMDA coding: Hindi ka coding',
            ),
            null => const StatusChip(
              key: Key('coding-badge'),
              tone: ChipTone.neutral,
              icon: CupertinoIcons.car_detailed,
              label: '…',
              semanticsLabel: 'Tinitingnan ang coding',
            ),
          },
          const SizedBox(width: AppSpace.xs),
          OfflineReadyBadge(ready: modelsReady, short: true),
          const SizedBox(width: AppSpace.xs),
          switch (gps) {
            AsyncData(value: true) => const StatusChip(
              key: Key('gps-chip'),
              tone: ChipTone.info,
              icon: CupertinoIcons.location_fill,
              label: '',
              semanticsLabel: 'GPS handa',
            ),
            AsyncData() || AsyncError() => const StatusChip(
              key: Key('gps-chip'),
              tone: ChipTone.neutral,
              icon: CupertinoIcons.location_slash_fill,
              label: '',
              semanticsLabel: 'Walang GPS',
            ),
            _ => const StatusChip(
              key: Key('gps-chip'),
              tone: ChipTone.neutral,
              icon: CupertinoIcons.location,
              label: '',
              semanticsLabel: 'Hinahanap ang GPS',
            ),
          },
        ],
      ),
    );
  }
}
