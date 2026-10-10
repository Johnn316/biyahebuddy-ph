import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/law_pill.dart';
import '../../violation/controllers/violation_controller.dart';
import '../../violation/screens/officer_message_screen.dart';
import '../controllers/answer_format.dart';
import '../controllers/chat_controller.dart';
import 'law_sheet.dart';

/// What sits under a guided na-flag message: violation chips, or the fine
/// card (+ IPAKITA), or — no match — chips + "Buksan ang Na-flag ako".
class FlagFooter extends StatelessWidget {
  const FlagFooter({super.key, required this.message, required this.onChip});

  final ChatMessage message;
  final void Function(String violation, Agency agency) onChip;

  @override
  Widget build(BuildContext context) {
    final agency = message.agency ?? Agency.mmda;
    return switch (message.flag) {
      FlagStep.fine when message.fine != null => FlagFineCard(
        fine: message.fine!,
      ),
      FlagStep.noMatch => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Chips(chips: message.chips, onTap: (c) => onChip(c, agency)),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton.icon(
            key: const Key('flag-open-violation'),
            onPressed: () => context.go(Routes.violation),
            icon: const Icon(CupertinoIcons.flag_fill),
            label: const Text('Buksan ang Na-flag ako'),
          ),
        ],
      ),
      FlagStep.askViolation => _Chips(
        chips: message.chips,
        onTap: (c) => onChip(c, agency),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.chips, required this.onTap});

  final List<String> chips;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: [
        for (final (i, c) in chips.indexed)
          ActionChip(
            key: Key('flag-chip-$i'),
            label: Text(c),
            labelStyle: context.text.titleSmall?.copyWith(
              color: context.colors.primary,
            ),
            backgroundColor: context.palette.primaryTint,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap(c);
            },
          ),
      ],
    );
  }
}

/// One structured card: Violation · Multa (big ₱, agency) · Batas (pill →
/// law sheet) · Ano ang gagawin · IPAKITA.
class FlagFineCard extends StatelessWidget {
  const FlagFineCard({super.key, required this.fine});

  final Fine fine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cite = citationPattern.firstMatch(fine.legalBasis)?.group(0);
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: 4),
      child: Text(
        t,
        style: context.text.labelLarge?.copyWith(
          color: p.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Container(
      key: const Key('flag-fine-card'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.sm,
        AppSpace.md + 2,
        AppSpace.md + 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label('VIOLATION'),
          Text(fine.violation, style: context.text.titleMedium),
          label('MULTA · ${fine.agency.label}'),
          Text(
            formatPeso(fine.amount),
            key: const Key('flag-fine-amount'),
            style: context.text.displaySmall?.copyWith(
              color: p.cautionText,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          label('BATAS'),
          if (cite != null)
            Align(
              alignment: Alignment.centerLeft,
              child: LawPill(
                cite,
                key: const Key('flag-law-pill'),
                onTap: () => showLawSheet(context, cite),
              ),
            ),
          Text(
            fine.legalBasis,
            style: context.text.bodyMedium?.copyWith(color: p.muted),
          ),
          label('ANO ANG GAGAWIN'),
          for (final (i, s) in flagSteps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}.',
                      style: context.text.bodyLarge?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(child: Text(s, style: context.text.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          FilledButton.icon(
            key: const Key('flag-ipakita'),
            onPressed: () => OfficerMessageScreen.open(context, fine),
            icon: const Icon(CupertinoIcons.eye_fill),
            label: const Text('IPAKITA sa enforcer'),
          ),
        ],
      ),
    );
  }
}
