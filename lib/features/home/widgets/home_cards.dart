import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/scale_down_to_fit.dart';

/// Red gradient hero — the largest thing on Home.
class EmergencyHeroCard extends StatelessWidget {
  const EmergencyHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onEmergency;
    return Semantics(
      button: true,
      label: 'EMERGENCY. Naaksidente ako',
      excludeSemantics: true,
      child: AppCard(
        gradient: p.emergencyGradient,
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: ScaleDownToFit(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: on.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.sos_rounded, size: 76, color: on),
              ),
              const SizedBox(height: 14),
              Text(
                'EMERGENCY',
                textAlign: TextAlign.center,
                style: context.text.displayLarge?.copyWith(
                  color: on,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Naaksidente ako',
                textAlign: TextAlign.center,
                style: context.text.headlineMedium?.copyWith(
                  color: on.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern action card: tinted icon badge, bold title, short subtitle.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: ScaleDownToFit(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(title, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.text.bodyMedium?.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
