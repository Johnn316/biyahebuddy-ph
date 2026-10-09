import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../emergency/screens/qr_exchange_screen.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_widgets.dart';
import '../widgets/sos_button.dart';

/// Home = car dashboard (docs/DESIGN.md §9.1): greeting · status chips ·
/// SOS hero · 2×2 quick actions · "Tip ng araw".
///
/// "Fit" layout: everything at natural size except the SOS area, which takes
/// exactly the space left — all visible above the tab bar. Short screens use
/// compact chips/tiles and skip the tip. "Scroll" layout only for extreme
/// cases (largest font, tiny screen).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider).valueOrNull;
    final tip = ref.watch(tipOfDayProvider).valueOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final usable = viewport.maxHeight - bottomInset;
            final compact = usable < 700 || scale > 1.3;
            final scroll = usable < 420 || scale > 1.5;
            final showTip = tip != null && !compact;
            final width =
                math.min(viewport.maxWidth, AppSizes.maxContentWidth) -
                2 * AppSpace.md;

            final header = _Header(status: status, compact: compact);
            final chips = HomeStatusChips(
              coding: status?.coding,
              scroll: compact,
            );
            // Tall tiles only when each tile is wide enough (tablets);
            // phones use the compact icon-beside-title tile.
            final grid = _ActionGrid(compact: compact || width < 560);
            final tipCard = showTip
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: TipOfDayCard(
                      tip: tip,
                      onTap: () => context.go(
                        Uri(
                          path: Routes.chat,
                          queryParameters: {
                            'q':
                                'Ipaliwanag ang ${tip.citation} '
                                '(${tip.title})',
                          },
                        ).toString(),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
            final padding = EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              bottomInset + AppSpace.sm,
            );

            if (scroll) {
              return ListView(
                padding: padding,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: AppSpace.sm),
                        chips,
                        const SizedBox(height: AppSpace.md),
                        _SosArea(diameter: width * 0.5),
                        const SizedBox(height: AppSpace.md),
                        grid,
                        tipCard,
                      ],
                    ),
                  ),
                ],
              );
            }
            return Padding(
              padding: padding,
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: AppSpace.sm),
                    chips,
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // Room left for the circle after its sublabel.
                          final below = 24 * scale + AppSpace.sm + 16;
                          double sos(double h) =>
                              ((h - below) / SosButton.glowRoom)
                                  .clamp(96.0, math.max(96.0, width * 0.6))
                                  .toDouble();
                          // The tip only if SOS can stay a hero (≥ 45% of
                          // the width) with it; SOS always wins the space.
                          final tipH = 132 * scale + AppSpace.sm;
                          final withTip =
                              showTip &&
                              sos(box.maxHeight - tipH) >= width * 0.45;
                          return Column(
                            children: [
                              Expanded(
                                child: _SosArea(
                                  diameter: sos(
                                    box.maxHeight - (withTip ? tipH : 0),
                                  ),
                                  fill: true,
                                ),
                              ),
                              if (withTip) tipCard,
                            ],
                          );
                        },
                      ),
                    ),
                    grid,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.status, required this.compact});

  final HomeStatus? status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final greeting = s == null
        ? 'Magandang araw'
        : '${s.greeting}, ${s.firstName}';
    final plate = s == null ? null : '${s.plateNo} · ${s.vehicleType}';
    final title = Text(
      greeting,
      maxLines: compact ? 1 : 2,
      style: compact ? context.text.headlineLarge : context.text.displaySmall,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: title,
          )
        else
          title,
        if (plate != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              plate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall?.copyWith(
                color: context.palette.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

/// SOS circle + "Pindutin kapag naaksidente" (below the circle: small text
/// never sits on bright red).
class _SosArea extends StatelessWidget {
  const _SosArea({required this.diameter, this.fill = false});

  final double diameter;

  /// Centered in its box, scrolling internally if the estimate was tight.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SosButton(
          diameter: diameter,
          onTap: () => context.push(Routes.emergency),
        ),
        Text(
          'Pindutin kapag naaksidente',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(
            color: context.palette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (!fill) return content;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: content,
      ),
    );
  }
}

class _ActionGrid extends ConsumerWidget {
  const _ActionGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final p = context.palette;
    final tiles = [
      ActionTile(
        tapKey: const Key('home-chat'),
        compact: compact,
        icon: CupertinoIcons.chat_bubble_2_fill,
        iconColor: context.colors.primary,
        title: 'Tanong kay Buddy',
        subtitle: 'Batas at multa, offline',
        onTap: () => context.go(Routes.chat),
      ),
      ActionTile(
        tapKey: const Key('home-violation'),
        compact: compact,
        icon: CupertinoIcons.flag_fill,
        iconColor: p.cautionText,
        title: 'Na-flag ako',
        subtitle: 'Alamin ang multa',
        onTap: () => context.go(Routes.violation),
      ),
      ActionTile(
        tapKey: const Key('home-qr'),
        compact: compact,
        icon: CupertinoIcons.qrcode,
        iconColor: context.colors.primary,
        title: 'QR Exchange',
        subtitle: 'Ipakita sa kabilang driver',
        onTap: () {
          final pr = profile;
          if (pr != null) QrExchangeScreen.open(context, pr);
        },
      ),
      ActionTile(
        tapKey: const Key('home-share-location'),
        compact: compact,
        icon: CupertinoIcons.location_fill,
        iconColor: p.success,
        title: 'Ibahagi lokasyon',
        subtitle: 'I-text sa contacts',
        onTap: () => context.push('${Routes.emergency}?section=contacts'),
      ),
    ];
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: b),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(tiles[0], tiles[1]),
        const SizedBox(height: AppSpace.sm),
        row(tiles[2], tiles[3]),
      ],
    );
  }
}
