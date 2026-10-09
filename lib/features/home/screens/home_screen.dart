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
              StatusStrip(onProfileTap: () => context.push(Routes.profile)),
              const SizedBox(height: AppSizes.gap),
              Expanded(
                flex: 3,
                child: BigActionButton(
                  label: 'EMERGENCY',
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
                        label: 'Tanong kay\nBuddy',
                        icon: Icons.record_voice_over,
                        color: AppColors.primary,
                        onPressed: () => context.push(Routes.chat),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gap),
                    Expanded(
                      child: BigActionButton(
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
