import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_widgets.dart';

/// Home = driving co-pilot dashboard (docs/DESIGN.md §9.1):
/// top bar · "Sasakyan mo" · "Tanong kay Buddy" hero · Na-flag + Tip ng araw
/// · SOS bar pinned above the tab bar.
///
/// The middle fills the screen (cards grow into spare room, capped on
/// tablets); if it doesn't fit (small screen, huge font) it scrolls while
/// the SOS bar stays put.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Na-flag / Tip cards never grow taller than this (tablets).
  static const _maxCardHeight = 240.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider).valueOrNull;
    final tip = ref.watch(tipOfDayProvider).valueOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final pad = MediaQuery.paddingOf(context);
    // Short screens (small phones, tablets in landscape) or big text: the
    // compact variants keep everything above the tab bar.
    final compact =
        MediaQuery.sizeOf(context).height - pad.top - pad.bottom < 660 ||
        scale > 1.2;

    void askBuddy([String? q]) => context.go(
      Uri(
        path: Routes.chat,
        queryParameters: q == null ? {'focus': '1'} : {'q': q},
      ).toString(),
    );

    final cards = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FlaggedCard(
            compact: compact,
            onTap: () => context.go(Routes.violation),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: TipSignCard(
            compact: compact,
            tip: tip,
            onTap: () => askBuddy(
              tip == null
                  ? null
                  : 'Ipaliwanag ang ${tip.citation} (${tip.title})',
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.md,
            0,
            AppSpace.md,
            bottomInset + AppSpace.sm,
          ),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeTopBar(
                  name: status?.name,
                  onProfile: () => context.go(Routes.profile),
                ),
                Expanded(
                  child: CustomScrollView(
                    key: const Key('home-scroll'),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpace.xxs,
                            bottom: AppSpace.sm,
                          ),
                          // Spare room is shared evenly between the blocks.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              VehicleCard(
                                compact: compact,
                                status: status,
                                onTap: () => context.go(Routes.profile),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.sm,
                                ),
                                child: AskBuddyHero(
                                  compact: compact,
                                  onAsk: askBuddy,
                                  onTopic: askBuddy,
                                ),
                              ),
                              Flexible(
                                child: ConstrainedBox(
                                  // No cap at large text: content first.
                                  constraints: BoxConstraints(
                                    maxHeight: scale > 1.2
                                        ? double.infinity
                                        : _maxCardHeight,
                                  ),
                                  child: cards,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SosBar(onTap: () => context.push(Routes.emergency)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
