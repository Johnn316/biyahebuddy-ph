import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_form.dart';
import '../widgets/theme_mode_picker.dart';

/// Profile tab: large title, appearance settings, editable driver profile.
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
    // As a tab it stays put; if it was pushed (e.g. from Emergency), go back.
    if (ok && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final saving = ref.watch(profileSaveControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // .when keeps showing the form while profileProvider refreshes.
        child: profile.when(
          data: (value) => ProfileForm(
            initial: value,
            submitLabel: 'I-save',
            saving: saving,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LargeTitle('Profile', subtitle: value?.name),
                const ThemeModePicker(),
              ],
            ),
            onSubmit: (p) => _save(context, ref, p),
          ),
          error: (_, _) =>
              const Center(child: Text('Hindi ma-load ang profile.')),
          loading: () => const Center(child: CupertinoActivityIndicator()),
        ),
      ),
    );
  }
}
