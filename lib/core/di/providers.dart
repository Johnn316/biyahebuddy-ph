import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_data.dart';
import '../contracts/contracts.dart';
import '../fakes/fakes.dart';

/// Single switch: true = fakes (frontend dev), false = real on-device
/// backends (lib/data/). When false, main() awaits `LocalData.init()`.
const bool useFakes = false;

/// Widget tests don't run main(), so LocalData is never initialised there;
/// they get the fakes for any provider they don't override. Only under
/// `flutter test` (FLUTTER_TEST is set) — the real app never falls back.
final bool _inFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

bool get _fake => useFakes || (_inFlutterTest && !LocalData.isReady);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => _fake ? FakeProfileRepository() : LocalData.instance.profiles,
);

final codingServiceProvider = Provider<CodingService>(
  (ref) => _fake ? FakeCodingService() : LocalData.instance.coding,
);

final finesRepositoryProvider = Provider<FinesRepository>(
  (ref) => _fake ? FakeFinesRepository() : LocalData.instance.fines,
);

final hotlineRepositoryProvider = Provider<HotlineRepository>(
  (ref) => _fake ? FakeHotlineRepository() : LocalData.instance.hotlines,
);

final aiAssistantProvider = Provider<AiAssistant>(
  (ref) => _fake ? FakeAiAssistant() : LocalData.instance.ai,
);

final sosServiceProvider = Provider<SosService>(
  (ref) => _fake ? FakeSosService() : LocalData.instance.sos,
);

final speechServiceProvider = Provider<SpeechService>(
  (ref) => _fake ? FakeSpeechService() : LocalData.instance.speech,
);

final modelManagerProvider = Provider<ModelManager>(
  (ref) => _fake ? FakeModelManager() : LocalData.instance.models,
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
