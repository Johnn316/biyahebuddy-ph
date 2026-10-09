import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_form.dart';
import '../widgets/theme_mode_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final ok = await ref
        .read(profileSaveControllerProvider.notifier)
        .save(profile);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Na-save ang profile!' : 'Hindi na-save. Subukan ulit.',
        ),
      ),
    );
    if (ok) _back(context);
  }

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final saving = ref.watch(profileSaveControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _back(context)),
        title: const Text('Profile'),
      ),
      // .when keeps showing the form while profileProvider refreshes after save.
      body: profile.when(
        data: (value) => ProfileForm(
          initial: value,
          submitLabel: 'I-save',
          saving: saving,
          header: const ThemeModePicker(),
          onSubmit: (p) => _save(context, ref, p),
        ),
        error: (_, _) =>
            const Center(child: Text('Hindi ma-load ang profile.')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
