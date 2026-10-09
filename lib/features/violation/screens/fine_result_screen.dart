import 'package:flutter/material.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
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
    final text = Theme.of(context).textTheme;

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(s, style: text.bodyMedium?.copyWith(color: Colors.white70)),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    border: Border.all(color: AppColors.accent, width: 3),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fine.violation, style: text.headlineMedium),
                        label('Multa'),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatPeso(fine.amount),
                            key: const Key('fine-amount'),
                            style: text.displayLarge?.copyWith(
                              fontSize: 64,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        label('Ahensya'),
                        Text(
                          '${fine.agency.label} — ${fine.agency.description}',
                          style: text.titleLarge,
                        ),
                        label('Legal basis'),
                        Text(fine.legalBasis, style: text.titleLarge),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Humingi ng official ticket. Huwag magbayad '
                                  'on the spot nang walang resibo.',
                                  style: text.titleLarge,
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(88),
                  textStyle: text.displayLarge?.copyWith(fontSize: 32),
                ),
                onPressed: () => OfficerMessageScreen.open(context, fine),
                icon: const Icon(Icons.fullscreen, size: 40),
                label: const Text('IPAKITA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
