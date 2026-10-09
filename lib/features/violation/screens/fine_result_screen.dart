import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/violation_controller.dart';
import 'officer_message_screen.dart';

/// Result as an inset card + big IPAKITA button (thumb zone).
class FineResultScreen extends StatelessWidget {
  const FineResultScreen({super.key, required this.fine});

  final Fine fine;

  static Future<void> open(BuildContext context, Fine fine) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => FineResultScreen(fine: fine)));

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final p = context.palette;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          Text(value, style: context.text.titleMedium),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Multa · ${fine.agency.label}')),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      GroupedSection(
                        margin: const EdgeInsets.only(top: 8),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fine.violation,
                                  style: context.text.headlineMedium,
                                ),
                                const SizedBox(height: 10),
                                Text('Multa', style: context.text.bodySmall),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    formatPeso(fine.amount),
                                    key: const Key('fine-amount'),
                                    style: context.text.displayLarge?.copyWith(
                                      fontSize: 60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          row(
                            'Ahensya',
                            '${fine.agency.label} — ${fine.agency.description}',
                          ),
                          row('Legal basis', fine.legalBasis),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(CupertinoIcons.doc_text_fill, color: p.accent),
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('ipakita'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    textStyle: context.text.headlineSmall,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    OfficerMessageScreen.open(context, fine);
                  },
                  icon: const Icon(CupertinoIcons.fullscreen, size: 28),
                  label: const Text('IPAKITA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
