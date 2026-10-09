import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Ticks every minute so the coding status flips on time (e.g. at 7:00 AM).
final _minuteTickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

typedef HomeStatus = ({String plateNo, CodingStatus coding});

/// Plate + MMDA coding status for the home status strip.
/// null = no profile saved yet.
final homeStatusProvider = FutureProvider.autoDispose<HomeStatus?>((ref) async {
  final now = ref.watch(_minuteTickProvider).valueOrNull ?? DateTime.now();
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final coding = ref
      .watch(codingServiceProvider)
      .statusFor(profile.plateNo, now);
  return (plateNo: profile.plateNo, coding: coding);
});
