import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../widgets/checklist_section.dart';
import '../widgets/contacts_section.dart';
import '../widgets/hotlines_section.dart';
import '../widgets/medical_card.dart';
import '../widgets/safety_check.dart';
import 'qr_exchange_screen.dart';

/// Full-screen (above the tab bar). Opens in one tap from Home, no confirm.
/// Order: Ligtas ka ba → (911) → contacts → hotlines → checklist → medical → QR.
/// `/emergency?section=contacts` scrolls straight to the contacts.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  final _contactsKey = GlobalKey();

  bool _jumped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_jumped) return;
    _jumped = true;
    final section = GoRouterState.of(context).uri.queryParameters['section'];
    if (section != 'contacts') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _contactsKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_octagon_fill,
              color: p.emergency,
            ),
            const SizedBox(width: 8),
            Text(
              'Emergency',
              style: context.text.titleLarge?.copyWith(color: p.emergency),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SafetyCheck(),
                  ContactsSection(
                    key: _contactsKey,
                    contacts: profile?.contacts ?? const [],
                  ),
                  const HotlinesSection(),
                  const ChecklistSection(),
                  if (profile != null) ...[
                    MedicalCard(profile: profile),
                    GroupedSection(
                      children: [
                        GroupedTile(
                          tapKey: const Key('open-qr'),
                          leading: IconSquare(
                            CupertinoIcons.qrcode,
                            color: context.colors.primary,
                          ),
                          title: 'QR Exchange',
                          subtitle: 'Ipakita sa kabilang driver',
                          onTap: () => QrExchangeScreen.open(context, profile),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
