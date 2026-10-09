import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../emergency/screens/qr_exchange_screen.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_widgets.dart';
import '../widgets/sos_button.dart';

/// Home tab: large greeting, coding pill, SOS hero, quick pills, shortcuts.
///
/// "Fit" layout (normal): header and shortcuts at natural size, the SOS area
/// takes exactly the space left and sizes the circle to it — everything
/// visible above the tab bar. "Scroll" layout only for extreme cases
/// (tiny screen + very large font).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider).valueOrNull;
    final profile = ref.watch(profileProvider).valueOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final usable = viewport.maxHeight - bottomInset;
            final compact = usable < 700;
            final scroll = usable < 380 * scale;
            final width =
                math.min(viewport.maxWidth, AppSizes.maxContentWidth) - 32;

            final header = _Header(status: status, compact: compact);
            final shortcuts = _Shortcuts(compact: compact);
            Widget hero(double diameter, {required bool fixed}) => _SosArea(
              diameter: diameter,
              spread: compact ? 1.12 : SosButton.ringSpread,
              fixed: fixed,
              profile: profile,
            );

            final padding = EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12);
            if (scroll) {
              return ListView(
                padding: padding,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: 12),
                        hero(width * 0.5, fixed: true),
                        shortcuts,
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
                          // Room left for the circle after label + pills.
                          final below =
                              23 * scale +
                              10 +
                              math.max(52, 24 * scale + 20) +
                              16;
                          final spread = compact ? 1.12 : SosButton.ringSpread;
                          final d = ((box.maxHeight - below) / spread).clamp(
                            96.0,
                            math.max(96.0, width * 0.6),
                          );
                          return hero(d.toDouble(), fixed: false);
                        },
                      ),
                    ),
                    shortcuts,
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
    final subtitle = s == null ? null : '${s.plateNo} · ${s.vehicleType}';

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: context.text.headlineLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (subtitle != null)
                Text(
                  subtitle,
                  style: context.text.titleSmall?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              CodingPill(coding: s?.coding),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LargeTitle(greeting, subtitle: subtitle),
        const SizedBox(height: 10),
        CodingPill(coding: s?.coding),
        if (s != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              s.coding.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// SOS circle + "Pindutin kapag naaksidente" + the two pill actions.
class _SosArea extends StatelessWidget {
  const _SosArea({
    required this.diameter,
    required this.spread,
    required this.fixed,
    required this.profile,
  });

  final double diameter;
  final double spread;

  /// true = natural height (scroll layout); false = centered in its box and
  /// scrolls internally if the estimate was too optimistic.
  final bool fixed;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SosButton(
          diameter: diameter,
          layoutSpread: spread,
          onTap: () => context.push(Routes.emergency),
        ),
        Text(
          'Pindutin kapag naaksidente',
          textAlign: TextAlign.center,
          style: context.text.titleMedium?.copyWith(
            color: context.palette.muted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillAction(
                key: const Key('home-share-location'),
                icon: CupertinoIcons.location_fill,
                label: 'Ibahagi lokasyon',
                onTap: () =>
                    context.push('${Routes.emergency}?section=contacts'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillAction(
                key: const Key('home-qr'),
                icon: CupertinoIcons.qrcode,
                label: 'QR Exchange',
                onTap: () {
                  final p = profile;
                  if (p != null) QrExchangeScreen.open(context, p);
                },
              ),
            ),
          ],
        ),
      ],
    );
    if (fixed) return content;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GroupedSection(
      margin: const EdgeInsets.only(top: 12),
      separatorIndent: 64,
      children: [
        GroupedTile(
          tapKey: const Key('home-chat'),
          minHeight: 56,
          leading: IconSquare(
            CupertinoIcons.chat_bubble_2_fill,
            color: context.colors.primary,
          ),
          title: 'Tanong kay Buddy',
          subtitle: compact ? null : 'Batas at multa, kahit offline',
          onTap: () => context.go(Routes.chat),
        ),
        GroupedTile(
          tapKey: const Key('home-violation'),
          minHeight: 56,
          leading: IconSquare(
            CupertinoIcons.flag_fill,
            color: context.palette.accent,
          ),
          title: 'Na-flag ako',
          subtitle: compact ? null : 'Alamin ang multa at ang batas',
          onTap: () => context.go(Routes.violation),
        ),
      ],
    );
  }
}
