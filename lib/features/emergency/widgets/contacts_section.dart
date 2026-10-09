import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_common.dart';

/// Emergency contacts from the saved profile: "I-text lahat" + per-contact
/// call / text buttons, in an inset grouped list.
class ContactsSection extends ConsumerWidget {
  const ContactsSection({super.key, required this.contacts});

  final List<EmergencyContact> contacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(sosSmsControllerProvider).isLoading;
    final p = context.palette;

    if (contacts.isEmpty) {
      return GroupedSection(
        header: 'Emergency contacts',
        children: [
          GroupedTile(
            leading: IconSquare(
              CupertinoIcons.person_add_solid,
              color: context.colors.primary,
            ),
            title: 'Magdagdag ng contact',
            subtitle: 'Wala kang naka-save na contact.',
            onTap: () => context.go(Routes.profile),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          header: 'Emergency contacts',
          footer: 'Ite-text ang iyong GPS location at kalagayan.',
          separatorIndent: 72,
          children: [
            for (final (i, c) in contacts.indexed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: p.elevated,
                      child: Text(
                        c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                        style: context.text.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: context.text.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(c.phone, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    _RoundAction(
                      key: Key('call-contact-$i'),
                      tooltip: 'Tawagan',
                      icon: CupertinoIcons.phone_fill,
                      color: p.success,
                      onColor: p.onSuccess,
                      onTap: () => dialNumber(context, ref, c.phone),
                    ),
                    const SizedBox(width: 8),
                    _RoundAction(
                      key: Key('text-contact-$i'),
                      tooltip: 'I-text',
                      icon: CupertinoIcons.chat_bubble_fill,
                      color: context.colors.primary,
                      onColor: context.colors.onPrimary,
                      onTap: sending
                          ? null
                          : () => textContacts(context, ref, [c]),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('text-all'),
          style: FilledButton.styleFrom(
            backgroundColor: p.accent,
            foregroundColor: p.onAccent,
            minimumSize: const Size.fromHeight(64),
          ),
          onPressed: sending
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  textContacts(context, ref, contacts);
                },
          icon: sending
              ? const SizedBox.square(
                  dimension: 22,
                  child: CupertinoActivityIndicator(),
                )
              : const Icon(CupertinoIcons.location_fill),
          label: Text(sending ? 'Sine-send…' : 'I-text lahat'),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color onColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onColor,
        minimumSize: const Size(52, 52),
      ),
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      icon: Icon(icon, size: 24),
    );
  }
}
