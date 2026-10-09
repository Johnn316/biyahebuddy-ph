import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';

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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('QR Exchange')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ipa-scan sa kabilang driver',
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
              const SizedBox(height: AppSizes.gap),
              // QR takes all remaining space, stays square, white quiet zone.
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
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
                style: text.titleLarge,
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
    );
  }
}
