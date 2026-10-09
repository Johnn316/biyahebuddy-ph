import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';

/// Info for responders: name, age, blood type, insurance.
class MedicalCard extends StatelessWidget {
  const MedicalCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const none = 'Hindi nakalagay';
    final insurance = [
      profile.insurer,
      if (profile.policyNo != null) 'Policy ${profile.policyNo}',
    ].nonNulls.join(' · ');

    Widget field(String label, String value, {TextStyle? style}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.bodySmall),
        Text(value, style: style ?? context.text.titleLarge),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Medical info',
          icon: Icons.medical_information_rounded,
        ),
        AppCard(
          key: const Key('medical-card'),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field('Pangalan', profile.name)),
                  const SizedBox(width: 12),
                  field('Edad', '${profile.age}'),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bloodtype_rounded, size: 36, color: p.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: field(
                        'Blood type',
                        profile.bloodType ?? none,
                        style: profile.bloodType == null
                            ? context.text.titleLarge
                            : context.text.displayMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              field('Insurance', insurance.isEmpty ? none : insurance),
            ],
          ),
        ),
      ],
    );
  }
}
