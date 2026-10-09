import 'package:flutter/cupertino.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';

/// Info for responders: name, age, blood type, insurance.
class MedicalCard extends StatelessWidget {
  const MedicalCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    const none = 'Hindi nakalagay';
    final insurance = [
      profile.insurer,
      if (profile.policyNo != null) 'Policy ${profile.policyNo}',
    ].nonNulls.join(' · ');

    Widget row(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          Text(value, style: style ?? context.text.titleMedium),
        ],
      ),
    );

    return GroupedSection(
      key: const Key('medical-card'),
      header: 'Medical info',
      children: [
        row('Pangalan', profile.name),
        row('Edad', '${profile.age}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconSquare(
                CupertinoIcons.drop_fill,
                color: context.palette.elevated,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blood type', style: context.text.bodySmall),
                    Text(
                      profile.bloodType ?? none,
                      style: profile.bloodType == null
                          ? context.text.titleMedium
                          : context.text.displaySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        row('Insurance', insurance.isEmpty ? none : insurance),
      ],
    );
  }
}
