import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../controllers/emergency_controller.dart';

void showEmergencySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// One tap → phone dialer.
Future<void> dialNumber(
  BuildContext context,
  WidgetRef ref,
  String number,
) async {
  try {
    await ref.read(sosServiceProvider).openDialer(number);
  } catch (_) {
    if (context.mounted) {
      showEmergencySnack(context, 'Hindi mabuksan ang dialer. I-dial: $number');
    }
  }
}

/// Texts the SOS message (with GPS) to [contacts] and reports the result.
Future<void> textContacts(
  BuildContext context,
  WidgetRef ref,
  List<EmergencyContact> contacts,
) async {
  final ok = await ref.read(sosSmsControllerProvider.notifier).send(contacts);
  if (!context.mounted) return;
  showEmergencySnack(
    context,
    ok
        ? (contacts.length == 1
              ? 'Na-text si ${contacts.single.name}'
              : 'Na-text ang ${contacts.length} contact')
        : 'Hindi na-send ang text. Subukan ulit o tumawag.',
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
