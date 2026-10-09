import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';

/// Plain text so any phone camera can read it without our app.
String qrExchangeText(Profile p) => [
  'BiyaheBuddy PH',
  'Pangalan: ${p.name}',
  'Plate: ${p.plateNo}',
  'License: ${p.licenseNo}',
  'Insurer: ${p.insurer ?? '-'}',
  'Policy: ${p.policyNo ?? '-'}',
].join('\n');

/// Full-screen QR for exchanging details with the other driver.
class QrExchangeScreen extends StatelessWidget {
  const QrExchangeScreen({super.key, required this.profile});

  final Profile profile;

  static Future<void> open(BuildContext context, Profile profile) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => QrExchangeScreen(profile: profile),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Exchange')),
      // The QR is the point of this screen: cap text growth so the code keeps
      // most of the space even at the largest system font.
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ipa-scan sa kabilang driver',
                  textAlign: TextAlign.center,
                  style: context.text.headlineMedium,
                ),
                const SizedBox(height: AppSizes.gap),
                // QR takes all remaining space, stays square. Always black on
                // white (both themes) — scanners need maximum contrast.
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AppCard(
                        color: Colors.white,
                        padding: const EdgeInsets.all(18),
                        child: QrImageView(
                          key: const Key('qr-exchange'),
                          data: qrExchangeText(profile),
                          backgroundColor: Colors.white,
                          semanticsLabel: 'QR ng iyong detalye',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.gap),
                Text(
                  '${profile.name}\n${profile.plateNo} · ${profile.licenseNo}\n'
                  '${profile.insurer ?? 'Walang insurer'}'
                  '${profile.policyNo == null ? '' : ' · ${profile.policyNo}'}',
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ),
                const SizedBox(height: AppSizes.gap),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tapos na'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
