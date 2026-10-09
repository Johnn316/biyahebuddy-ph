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
import '../widgets/profile_card.dart';
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
            // ~68% of the SCREEN width (not the content column), never
            // wider than the content.
            // Capped at 380dp so tablets don't get a giant button.
            final sosMax = math.min(
              math.min(viewport.maxWidth * 0.68, width),
              380.0,
            );

            final header = ProfileCard(
              status: status,
              onTap: () => context.go(Routes.profile),
            );
            // Tall tiles only when each tile is wide enough (tablets);
            // phones use the compact icon-beside-title tile.
            final grid = _ActionGrid(
              compact: compact || width < 560,
              width: width,
            );
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
                        const SizedBox(height: AppSpace.md),
                        _SosArea(diameter: width * 0.6),
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
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // Room left for the circle after its sublabel.
                          final below = 24 * scale + AppSpace.sm + 16;
                          // SOS fills the free space up to ~68% of the width,
                          // shrinking gracefully on short screens.
                          double sos(double h) =>
                              ((h - below) / SosButton.glowRoom)
                                  .clamp(96.0, math.max(96.0, sosMax))
                                  .toDouble();
                          // The tip only if SOS stays a hero (≥ 60% of the
                          // width) with it; SOS always wins the space.
                          final tipH = 132 * scale + AppSpace.sm;
                          final withTip =
                              showTip &&
                              sos(box.maxHeight - tipH) >= sosMax * 0.92;
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
  const _ActionGrid({required this.compact, required this.width});

  final bool compact;

  /// Content width; each tile gets half (minus the gap).
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final p = context.palette;
    final tileWidth = (width - AppSpace.sm) / 2;
    // Subtitles all-or-nothing: shown only if every one fits on one line.
    const subtitles = [
      'Batas at multa',
      'Alamin ang multa',
      'Palitan ng detalye',
      'I-text sa contacts',
    ];
    final subsFit = subtitles.every(
      (t) => ActionTile.subtitleFits(context, t, tileWidth, compact: compact),
    );
    final w = subsFit ? tileWidth : null;
    final tiles = [
      ActionTile(
        tapKey: const Key('home-chat'),
        compact: compact,
        width: w,
        semanticsLabel: 'Tanong kay Buddy',
        icon: CupertinoIcons.chat_bubble_2_fill,
        iconColor: context.colors.primary,
        title: 'Buddy',
        subtitle: 'Batas at multa',
        onTap: () => context.go(Routes.chat),
      ),
      ActionTile(
        tapKey: const Key('home-violation'),
        compact: compact,
        width: w,
        semanticsLabel: 'Na-flag ako',
        icon: CupertinoIcons.flag_fill,
        iconColor: p.cautionText,
        title: 'Na-flag ako',
        subtitle: 'Alamin ang multa',
        onTap: () => context.go(Routes.violation),
      ),
      ActionTile(
        tapKey: const Key('home-qr'),
        compact: compact,
        width: w,
        semanticsLabel: 'QR Exchange',
        icon: CupertinoIcons.qrcode,
        iconColor: context.colors.primary,
        title: 'QR',
        subtitle: 'Palitan ng detalye',
        onTap: () {
          final pr = profile;
          if (pr != null) QrExchangeScreen.open(context, pr);
        },
      ),
      ActionTile(
        tapKey: const Key('home-share-location'),
        compact: compact,
        width: w,
        semanticsLabel: 'Ibahagi lokasyon',
        icon: CupertinoIcons.location_fill,
        iconColor: p.success,
        title: 'Lokasyon',
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
