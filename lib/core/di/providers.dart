import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_data.dart';
import '../contracts/contracts.dart';
import '../fakes/fakes.dart';

/// Single switch: true = fakes (frontend dev), false = real backend impls.
/// Backend flips this (or swaps individual providers) once lib/data/ is merged.
/// When false, main() must `await LocalData.init()` before runApp.
const bool useFakes = true;

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => useFakes ? FakeProfileRepository() : LocalData.instance.profiles,
);

final codingServiceProvider = Provider<CodingService>(
  (ref) => useFakes ? FakeCodingService() : LocalData.instance.coding,
);

final finesRepositoryProvider = Provider<FinesRepository>(
  (ref) => useFakes ? FakeFinesRepository() : LocalData.instance.fines,
);

final hotlineRepositoryProvider = Provider<HotlineRepository>(
  (ref) => useFakes ? FakeHotlineRepository() : LocalData.instance.hotlines,
);

final aiAssistantProvider = Provider<AiAssistant>(
  (ref) => useFakes ? FakeAiAssistant() : LocalData.instance.ai,
);

final sosServiceProvider = Provider<SosService>(
  (ref) => useFakes ? FakeSosService() : LocalData.instance.sos,
);

final speechServiceProvider = Provider<SpeechService>(
  (ref) => useFakes ? FakeSpeechService() : LocalData.instance.speech,
);

final modelManagerProvider = Provider<ModelManager>(
  (ref) => useFakes ? FakeModelManager() : LocalData.instance.models,
);

// ---------------------------------------------------------------------------
// Derived state shared by screens
// ---------------------------------------------------------------------------

final profileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);
