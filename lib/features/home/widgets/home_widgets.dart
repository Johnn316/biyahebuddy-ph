import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';
import '../controllers/home_controller.dart';

/// Rounded surface card that is one button (press scale + light haptic).
class _TapCard extends StatelessWidget {
  const _TapCard({
    required this.tapKey,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpace.md),
  });

  final Key tapKey;
  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Pressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? context.colors.surface,
            borderRadius: radius,
            boxShadow: p.cardShadow,
            border: Border(top: BorderSide(color: p.highlight, width: 0.5)),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: tapKey,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// App mark left, driver's initials right (→ Profile).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.name, required this.onProfile});

  final String? name;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initials = (name ?? '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: p.ringGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 22,
                color: p.onPrimaryFill,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: 'BiyaheBuddy',
                    children: [
                      TextSpan(
                        text: ' PH',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ],
                  ),
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Profile',
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('home-avatar'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onProfile();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
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
                        style: context.text.titleSmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData vehicleIcon(String type) => switch (type) {
  'Motorsiklo' => Icons.two_wheeler_rounded,
  'SUV/Van' => Icons.airport_shuttle_rounded,
  'Truck' => Icons.local_shipping_rounded,
  _ => Icons.directions_car_filled_rounded,
};

/// "Sasakyan mo": big PH plate, vehicle, one status line (coding ·
/// Offline-ready), dashed lane line along the bottom edge. Tap → Profile.
class VehicleCard extends ConsumerWidget {
  const VehicleCard({
    super.key,
    required this.status,
    required this.onTap,
    this.compact = false,
  });

  /// null while loading / no profile.
  final HomeStatus? status;
  final VoidCallback onTap;

  /// Short screens: no caption row, regular-size plate.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = status;
    final ready = ref.watch(modelManagerProvider).isReady;
    final coding = s?.coding;
    final (codingText, codingColor, codingIcon) = switch (coding) {
      CodingStatus(isCoding: true) => (
        'Coding ngayon',
        p.cautionText,
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      CodingStatus() => (
        'Hindi coding',
        p.success,
        CupertinoIcons.checkmark_circle_fill,
      ),
      null => ('Tinitingnan…', p.muted, CupertinoIcons.clock),
    };
    final statusStyle = context.text.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return _TapCard(
      tapKey: const Key('home-vehicle'),
      semanticsLabel: s == null
          ? 'Sasakyan mo'
          : 'Sasakyan mo: ${s.vehicleType}, plate ${s.plateNo}. '
                'MMDA coding: ${coding?.isCoding == true ? 'Coding ka ngayon' : 'Hindi ka coding'}. '
                '${ready ? 'Offline-ready' : 'Hindi pa naka-download si Buddy'}.',
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md,
              compact ? AppSpace.sm + 2 : AppSpace.md,
              AppSpace.md,
              (compact ? AppSpace.sm : AppSpace.md) + 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SASAKYAN MO',
                          style: context.text.labelSmall?.copyWith(
                            color: p.muted,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: AppIcon.sm,
                        color: p.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlateBadge(plate: s?.plateNo ?? '—', large: !compact),
                    if (s != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            vehicleIcon(s.vehicleType),
                            size: AppIcon.md,
                            color: p.muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              s.vehicleType,
                              style: context.text.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: compact ? AppSpace.xs : AppSpace.sm),
                // One status line; wraps (never cuts off) at huge fonts.
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      key: const Key('coding-badge'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(codingIcon, size: AppIcon.sm, color: codingColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            codingText,
                            style: statusStyle?.copyWith(color: codingColor),
                          ),
                        ),
                      ],
                    ),
                    Text('·', style: statusStyle?.copyWith(color: p.muted)),
                    Row(
                      key: const Key('offline-badge'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ready
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.arrow_down_circle_fill,
                          size: AppIcon.sm,
                          color: ready ? p.success : p.cautionText,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            ready ? 'Offline-ready' : 'I-download si Buddy',
                            style: statusStyle?.copyWith(
                              color: ready ? p.success : p.cautionText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Road motif: a dashed lane line along the bottom edge.
          Positioned(
            left: AppSpace.md,
            right: AppSpace.md,
            bottom: 8,
            height: 3,
            child: CustomPaint(painter: _LanePainter(p.accent)),
          ),
        ],
      ),
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    const dash = 18.0, gap = 12.0;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) => old.color != color;
}

/// White PH-style license plate: dark bold spaced characters, thin border.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.plate, this.large = false});

  final String plate;

  /// Home "Sasakyan mo" size, with "PILIPINAS" on top.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = Text(
      plate.toUpperCase(),
      style: (large ? context.text.headlineSmall : context.text.titleSmall)
          ?.copyWith(
            color: p.plateInk,
            fontWeight: FontWeight.w800,
            letterSpacing: large ? 2.6 : 1.8,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('plate-badge'),
        padding: large
            ? const EdgeInsets.fromLTRB(14, 4, 14, 6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: p.plateFill,
          borderRadius: BorderRadius.circular(large ? 8 : 6),
          border: Border.all(color: p.plateBorder, width: large ? 2 : 1.2),
        ),
        child: large
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PILIPINAS',
                    style: context.text.labelSmall?.copyWith(
                      color: p.plateInk.withValues(alpha: 0.7),
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  digits,
                ],
              )
            : digits,
      ),
    );
  }
}

/// Topic chips under the Ask field: label → question prefilled in Buddy.
const homeTopics = [
  ('Multa', 'Magkano ang multa kapag walang lisensya?'),
  ('Helmet', 'Ano ang multa kapag walang helmet?'),
  ('Overtaking', 'Kailan bawal mag-overtake?'),
  ('Aksidente', 'Nabangga ako, ano ang dapat kong gawin?'),
  ('Lisensya', 'Ano ang parusa sa expired na lisensya?'),
  ('Coding', 'Anong oras ang number coding ng MMDA?'),
];

/// Hero: "Tanong kay Buddy" — a search-style field + topic chips.
class AskBuddyHero extends StatelessWidget {
  const AskBuddyHero({
    super.key,
    required this.onAsk,
    required this.onTopic,
    this.compact = false,
  });

  final VoidCallback onAsk;
  final ValueChanged<String> onTopic;

  /// Short screens: no title row (the field says it all).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: p.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.raisedShadow,
        border: Border.all(color: p.highlight, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpace.sm : AppSpace.md,
          compact ? AppSpace.sm : AppSpace.md,
          compact ? AppSpace.sm : AppSpace.md,
          AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    size: AppIcon.md,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      'Tanong kay Buddy',
                      style: context.text.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            Semantics(
              button: true,
              label: "Ano'ng tanong mo sa batas trapiko? Buksan si Buddy.",
              excludeSemantics: true,
              child: Pressable(
                child: Material(
                  color: context.colors.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: context.colors.outline, width: 0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('home-chat'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onAsk();
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          6,
                          6,
                          6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: AppIcon.md,
                              color: p.muted,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                "Ano'ng tanong mo sa batas trapiko?",
                                style: context.text.bodyLarge?.copyWith(
                                  color: p.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: p.primaryFill,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_up,
                                size: 22,
                                color: p.onPrimaryFill,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // One swipeable row of topics.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final (label, question) in homeTopics)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.xs),
                      child: _TopicChip(
                        key: Key('topic-${label.toLowerCase()}'),
                        label: label,
                        onTap: () => onTopic(question),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Paksa: $label',
      excludeSemantics: true,
      child: Material(
        color: context.palette.primaryTint,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md - 2,
                vertical: AppSpace.xs,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Na-flag ako" quick card (ticket icon).
class FlaggedCard extends StatelessWidget {
  const FlaggedCard({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _TapCard(
      tapKey: const Key('home-violation'),
      semanticsLabel: 'Na-flag ako. Alamin ang tamang multa.',
      onTap: onTap,
      padding: EdgeInsets.all(compact ? AppSpace.sm + 2 : AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: p.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              CupertinoIcons.tickets_fill,
              size: 24,
              color: context.colors.primary,
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpace.sm),
          Text('Na-flag ako', style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Alamin ang tamang multa',
            style: context.text.bodyMedium?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}

/// "Tip ng araw" as an amber road sign: diamond icon, a short rule from
/// laws.json. Tap → Buddy explains it.
class TipSignCard extends StatelessWidget {
  const TipSignCard({
    super.key,
    required this.tip,
    required this.onTap,
    this.compact = false,
  });

  /// null while loading / no laws.
  final LawTip? tip;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = tip;
    final ink = p.onAccent;
    return _TapCard(
      tapKey: const Key('home-tip'),
      semanticsLabel: t == null
          ? 'Tip ng araw. Itanong kay Buddy.'
          : 'Tip ng araw: ${t.title}. ${t.citation}. Itanong kay Buddy.',
      onTap: onTap,
      color: p.accent,
      padding: EdgeInsets.all(compact ? AppSpace.sm + 2 : AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Diamond road-sign mark.
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: ink, width: 2.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Icon(
                      CupertinoIcons.exclamationmark,
                      size: 16,
                      color: ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'TIP NG ARAW',
                  style: context.text.labelSmall?.copyWith(
                    color: ink,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpace.sm),
          Text(
            t?.title ?? 'Alamin ang batas trapiko',
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium?.copyWith(color: ink),
          ),
          const SizedBox(height: 2),
          Text(
            t?.citation ?? 'Itanong kay Buddy',
            style: context.text.bodyMedium?.copyWith(
              color: ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact full-width SOS bar pinned above the tab bar: one tap → Emergency.
class SosBar extends StatefulWidget {
  const SosBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<SosBar> createState() => _SosBarState();
}

class _SosBarState extends State<SosBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.sosBreath,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.md);
    final on = p.onEmergency;
    return Semantics(
      button: true,
      label: 'SOS. Naaksidente ako. Buksan ang Emergency.',
      excludeSemantics: true,
      // Always one compact bar: text grows at most 1.3×.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Pressable(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: p.emergencyGradient,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: p.emergency.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('home-emergency'),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  widget.onTap();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: on.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.exclamationmark_shield_fill,
                            color: on,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        // "SOS · Naaksidente ako" wraps instead of cutting off.
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'SOS',
                                style: context.text.titleLarge?.copyWith(
                                  color: on,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                ' · ',
                                style: context.text.titleSmall?.copyWith(
                                  color: on,
                                ),
                              ),
                              Text(
                                'Naaksidente ako',
                                style: context.text.titleSmall?.copyWith(
                                  color: on,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Subtle "live" pulse dot.
                        FadeTransition(
                          key: const Key('sos-pulse'),
                          opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: on,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          color: on,
                          size: AppIcon.md,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
