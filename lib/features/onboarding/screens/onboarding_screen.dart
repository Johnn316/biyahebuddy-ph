import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/profile_form.dart';
import '../widgets/model_download_step.dart';

enum _Step { model, profile }

/// First launch: (a) one-time model download, (b) profile setup → Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late _Step _step = ref.read(modelManagerProvider).isReady
      ? _Step.profile
      : _Step.model;

  Future<void> _saveProfile(Profile profile) async {
    final ok = await ref
        .read(profileSaveControllerProvider.notifier)
        .save(profile);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hindi na-save. Subukan ulit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.model => Scaffold(
        body: ModelDownloadStep(
          onContinue: () => setState(() => _step = _Step.profile),
        ),
      ),
      _Step.profile => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Ang iyong profile'),
        ),
        body: ProfileForm(
          submitLabel: 'I-save at magsimula',
          saving: ref.watch(profileSaveControllerProvider).isLoading,
          onSubmit: _saveProfile,
        ),
      ),
    };
  }
}
