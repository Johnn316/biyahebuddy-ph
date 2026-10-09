import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/big_action_button.dart';
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
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('home-profile'),
                    tooltip: 'Profile',
                    icon: const Icon(Icons.account_circle, size: 40),
                    onPressed: () => context.push(Routes.profile),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gap),
              Expanded(
                flex: 3,
                child: BigActionButton(
                  key: const Key('home-emergency'),
                  label: 'EMERGENCY',
                  subtitle: 'Naaksidente ako',
                  icon: Icons.sos,
                  color: AppColors.emergency,
                  large: true,
                  onPressed: () => context.push(Routes.emergency),
                ),
              ),
              const SizedBox(height: AppSizes.gap),
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: BigActionButton(
                        key: const Key('home-chat'),
                        label: 'Tanong kay\nBuddy',
                        icon: Icons.record_voice_over,
                        color: AppColors.primary,
                        onPressed: () => context.push(Routes.chat),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gap),
                    Expanded(
                      child: BigActionButton(
                        key: const Key('home-violation'),
                        label: 'Na-flag\nako',
                        icon: Icons.local_police,
                        color: AppColors.accent,
                        foreground: Colors.black,
                        onPressed: () => context.push(Routes.violation),
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
