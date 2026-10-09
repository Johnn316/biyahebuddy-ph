import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/checklist_section.dart';
import '../widgets/contacts_section.dart';
import '../widgets/hotlines_section.dart';
import '../widgets/medical_card.dart';
import '../widgets/safety_check.dart';
import 'qr_exchange_screen.dart';

/// Opens in one tap from Home, no confirm dialog.
/// Order: Ligtas ka ba → (911) → contacts → hotlines → checklist → medical → QR.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.emergency,
        foregroundColor: p.onEmergency,
        titleTextStyle: context.text.headlineSmall?.copyWith(
          color: p.onEmergency,
        ),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Text('Emergency'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const SafetyCheck(),
            ContactsSection(contacts: profile?.contacts ?? const []),
            const HotlinesSection(),
            const ChecklistSection(),
            if (profile != null) ...[
              MedicalCard(profile: profile),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('open-qr'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(80),
                ),
                onPressed: () => QrExchangeScreen.open(context, profile),
                icon: const Icon(Icons.qr_code_2_rounded, size: 36),
                label: const Text('QR Exchange'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
