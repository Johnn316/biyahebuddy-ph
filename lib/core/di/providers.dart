import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_data.dart';
import '../contracts/contracts.dart';
import '../fakes/fakes.dart';

/// Single switch: true = fakes (frontend dev), false = real on-device
/// backends (lib/data/). When false, main() awaits `LocalData.init()`.
const bool useFakes = false;

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

/// Every contract provider replaced by its fake. For widget tests (which
/// don't run main(), so LocalData isn't initialised) and UI demos:
///   ProviderScope(overrides: fakeOverrides, child: App())
/// Riverpod rejects overriding one provider twice in a scope; for a
/// test-specific fake, nest another ProviderScope inside this one.
final List<Override> fakeOverrides = [
  profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
  codingServiceProvider.overrideWithValue(FakeCodingService()),
  finesRepositoryProvider.overrideWithValue(FakeFinesRepository()),
  hotlineRepositoryProvider.overrideWithValue(FakeHotlineRepository()),
  aiAssistantProvider.overrideWithValue(FakeAiAssistant()),
  sosServiceProvider.overrideWithValue(FakeSosService()),
  speechServiceProvider.overrideWithValue(FakeSpeechService()),
  modelManagerProvider.overrideWithValue(FakeModelManager()),
];
