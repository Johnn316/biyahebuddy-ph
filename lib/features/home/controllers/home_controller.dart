import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Plate + coding status for the home status strip.
final homeStatusProvider =
    FutureProvider<({String plateNo, CodingStatus coding})?>((ref) async {
      final profile = await ref.watch(profileProvider.future);
      if (profile == null) return null;
      final coding = ref
          .watch(codingServiceProvider)
          .statusFor(profile.plateNo, DateTime.now());
      return (plateNo: profile.plateNo, coding: coding);
    });
