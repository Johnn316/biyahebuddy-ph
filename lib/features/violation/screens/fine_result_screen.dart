import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../controllers/violation_controller.dart';
import 'officer_message_screen.dart';

/// Result card for one violation + big IPAKITA button (thumb zone).
class FineResultScreen extends StatelessWidget {
  const FineResultScreen({super.key, required this.fine});

  final Fine fine;

  static Future<void> open(BuildContext context, Fine fine) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => FineResultScreen(fine: fine)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = context.colors;

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 2),
      child: Text(s, style: context.text.bodySmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Multa · ${fine.agency.label}')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fine.violation,
                          style: context.text.headlineMedium,
                        ),
                        label('Multa'),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatPeso(fine.amount),
                            key: const Key('fine-amount'),
                            style: context.text.displayLarge?.copyWith(
                              fontSize: 60,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        label('Ahensya'),
                        Text(
                          '${fine.agency.label} — ${fine.agency.description}',
                          style: context.text.titleLarge,
                        ),
                        label('Legal basis'),
                        Text(fine.legalBasis, style: context.text.titleLarge),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                            border: Border.all(color: p.accent, width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: scheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Humingi ng official ticket. Huwag magbayad '
                                  'on the spot nang walang resibo.',
                                  style: context.text.titleMedium?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.gap),
              FilledButton.icon(
                key: const Key('ipakita'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(84),
                  textStyle: context.text.headlineMedium,
                ),
                onPressed: () => OfficerMessageScreen.open(context, fine),
                icon: const Icon(Icons.fullscreen_rounded, size: 36),
                label: const Text('IPAKITA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
