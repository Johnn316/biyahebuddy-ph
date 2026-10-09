import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/contracts.dart';
import '../fakes/fakes.dart';

/// Single switch: true = fakes (frontend dev), false = real backend impls.
/// Backend flips this (or swaps individual providers) once lib/data/ is merged.
const bool useFakes = true;

T _real<T>(String name) => throw UnimplementedError(
  '$name: real implementation not merged yet. '
  'Set useFakes = true or wire lib/data/ here.',
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => useFakes ? FakeProfileRepository() : _real('ProfileRepository'),
);

final codingServiceProvider = Provider<CodingService>(
  (ref) => useFakes ? FakeCodingService() : _real('CodingService'),
);

final finesRepositoryProvider = Provider<FinesRepository>(
  (ref) => useFakes ? FakeFinesRepository() : _real('FinesRepository'),
);

final hotlineRepositoryProvider = Provider<HotlineRepository>(
  (ref) => useFakes ? FakeHotlineRepository() : _real('HotlineRepository'),
);

final aiAssistantProvider = Provider<AiAssistant>(
  (ref) => useFakes ? FakeAiAssistant() : _real('AiAssistant'),
);

final sosServiceProvider = Provider<SosService>(
  (ref) => useFakes ? FakeSosService() : _real('SosService'),
);

// ---------------------------------------------------------------------------
// Derived state shared by screens
// ---------------------------------------------------------------------------

final profileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);
