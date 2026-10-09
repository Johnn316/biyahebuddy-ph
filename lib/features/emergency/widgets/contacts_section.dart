import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
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
    final p = context.palette;
    const title = SectionTitle(
      'Emergency contacts',
      icon: Icons.contact_phone_rounded,
    );

    if (contacts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          Text(
            'Wala kang naka-save na contact.',
            style: context.text.titleLarge,
          ),
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
        title,
        FilledButton.icon(
          key: const Key('text-all'),
          style: FilledButton.styleFrom(
            backgroundColor: p.accent,
            foregroundColor: p.onAccent,
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
              : const Icon(Icons.sms_rounded),
          label: Text(sending ? 'Sine-send…' : 'I-text lahat'),
        ),
        for (final (i, c) in contacts.indexed)
          AppCard(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: context.colors.primaryContainer,
                      foregroundColor: context.colors.onPrimaryContainer,
                      child: Text(
                        c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: context.text.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            c.phone,
                            style: context.text.bodyMedium?.copyWith(
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: Key('call-contact-$i'),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.success,
                          foregroundColor: p.onSuccess,
                        ),
                        onPressed: () => dialNumber(context, ref, c.phone),
                        icon: const Icon(Icons.call_rounded),
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
                        icon: const Icon(Icons.sms_rounded),
                        label: const FittedBox(child: Text('I-text')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
