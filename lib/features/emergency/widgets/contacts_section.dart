import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// Emergency contacts from the saved profile: "I-text lahat" + per-contact
/// [Tawagan] / [I-text].
class ContactsSection extends ConsumerWidget {
  const ContactsSection({super.key, required this.contacts});

  final List<EmergencyContact> contacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(sosSmsControllerProvider).isLoading;
    final text = Theme.of(context).textTheme;

    if (contacts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Emergency contacts'),
          Text('Wala kang naka-save na contact.', style: text.titleLarge),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push(Routes.profile),
            child: const Text('Magdagdag sa Profile'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Emergency contacts'),
        FilledButton.icon(
          key: const Key('text-all'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(72),
          ),
          onPressed: sending
              ? null
              : () => textContacts(context, ref, contacts),
          icon: sending
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Icon(Icons.sms),
          label: Text(sending ? 'Sine-send…' : 'I-text lahat'),
        ),
        for (final (i, c) in contacts.indexed)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    c.name,
                    style: text.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(c.phone, style: text.bodyLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: Key('call-contact-$i'),
                          onPressed: () => dialNumber(context, ref, c.phone),
                          icon: const Icon(Icons.call),
                          label: const FittedBox(child: Text('Tawagan')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: Key('text-contact-$i'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSizes.minTap),
                          ),
                          onPressed: sending
                              ? null
                              : () => textContacts(context, ref, [c]),
                          icon: const Icon(Icons.sms),
                          label: const FittedBox(child: Text('I-text')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
