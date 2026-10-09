import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';

class StatusStrip extends ConsumerWidget {
  const StatusStrip({super.key, required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(homeStatusProvider);
    final text = Theme.of(context).textTheme;

    final (plate, message, color) = switch (status) {
      AsyncData(value: final s?) => (
        s.plateNo,
        s.coding.message,
        s.coding.isCoding ? AppColors.warning : AppColors.ok,
      ),
      AsyncData() => (
        'Walang profile',
        'I-setup ang profile',
        AppColors.warning,
      ),
      AsyncError() => ('—', 'Hindi ma-load ang status', AppColors.warning),
      _ => ('…', 'Naglo-load…', AppColors.onSurface),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plate, style: text.titleLarge),
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: onProfileTap,
          ),
        ],
      ),
    );
  }
}
