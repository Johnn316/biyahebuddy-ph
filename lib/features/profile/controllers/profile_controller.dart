import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Saves the profile and refreshes everything that watches [profileProvider].
class ProfileSaveController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success.
  Future<bool> save(Profile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).save(profile),
    );
    if (state.hasError) return false;
    ref.invalidate(profileProvider);
    return true;
  }
}

final profileSaveControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileSaveController, void>(
      ProfileSaveController.new,
    );
