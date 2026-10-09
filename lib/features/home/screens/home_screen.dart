import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/home_cards.dart';
import '../widgets/status_strip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: StatusStrip()),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    key: const Key('home-profile'),
                    tooltip: 'Profile',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      backgroundColor: context.colors.surface,
                      side: BorderSide(color: context.colors.outline),
                    ),
                    icon: Icon(
                      Icons.person_rounded,
                      size: 30,
                      color: context.colors.primary,
                    ),
                    onPressed: () => context.push(Routes.profile),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gap),
              Expanded(
                flex: 3,
                child: EmergencyHeroCard(
                  key: const Key('home-emergency'),
                  onTap: () => context.push(Routes.emergency),
                ),
              ),
              const SizedBox(height: AppSizes.gap),
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ActionCard(
                        key: const Key('home-chat'),
                        title: 'Tanong kay Buddy',
                        subtitle: 'Batas at multa, offline',
                        icon: Icons.forum_rounded,
                        iconColor: context.colors.primary,
                        onTap: () => context.push(Routes.chat),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gap),
                    Expanded(
                      child: ActionCard(
                        key: const Key('home-violation'),
                        title: 'Na-flag ako',
                        subtitle: 'Alamin ang multa',
                        icon: Icons.local_police_rounded,
                        iconColor: context.palette.accent,
                        onTap: () => context.push(Routes.violation),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
