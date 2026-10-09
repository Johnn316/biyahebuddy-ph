import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import 'emergency_common.dart';

/// Info for responders: name, age, blood type, insurance.
class MedicalCard extends StatelessWidget {
  const MedicalCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const none = 'Hindi nakalagay';
    final insurance = [
      profile.insurer,
      if (profile.policyNo != null) 'Policy ${profile.policyNo}',
    ].nonNulls.join(' · ');

    Widget row(String label, String value, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: Colors.white70)),
          Text(value, style: big ? text.displayLarge : text.titleLarge),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Medical info'),
        Container(
          key: const Key('medical-card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: row('Pangalan', profile.name)),
                  row('Edad', '${profile.age}'),
                ],
              ),
              row('Blood type', profile.bloodType ?? none, big: true),
              row('Insurance', insurance.isEmpty ? none : insurance),
            ],
          ),
        ),
      ],
    );
  }
}
