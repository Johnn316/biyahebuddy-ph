import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Ticks every minute so the coding status and greeting flip on time.
final minuteTickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

typedef HomeStatus = ({
  String plateNo,
  String firstName,
  String vehicleType,
  CodingStatus coding,
  String greeting,
});

/// "Magandang umaga / hapon / gabi".
String greetingFor(DateTime now) => switch (now.hour) {
  < 12 => 'Magandang umaga',
  < 18 => 'Magandang hapon',
  _ => 'Magandang gabi',
};

/// Greeting, plate and MMDA coding status for the Home header.
/// null = no profile saved yet.
final homeStatusProvider = FutureProvider.autoDispose<HomeStatus?>((ref) async {
  final now = ref.watch(minuteTickProvider).valueOrNull ?? DateTime.now();
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final coding = ref
      .watch(codingServiceProvider)
      .statusFor(profile.plateNo, now);
  return (
    plateNo: profile.plateNo,
    firstName: profile.name.trim().split(RegExp(r'\s+')).first,
    vehicleType: profile.vehicleType,
    coding: coding,
    greeting: greetingFor(now),
  );
});
