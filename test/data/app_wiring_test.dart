import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app runs on the real on-device backends', () {
    expect(useFakes, isFalse);
  });

  test('under flutter test, un-overridden providers fall back to fakes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(aiAssistantProvider), isA<FakeAiAssistant>());
    expect(container.read(sosServiceProvider), isA<FakeSosService>());
  });

  test('fakeOverrides covers every contract provider (for widget tests)', () {
    final container = ProviderContainer(overrides: fakeOverrides);
    addTearDown(container.dispose);
    // Would throw (LocalData not initialised) if any provider were missing.
    container
      ..read(profileRepositoryProvider)
      ..read(codingServiceProvider)
      ..read(finesRepositoryProvider)
      ..read(hotlineRepositoryProvider)
      ..read(aiAssistantProvider)
      ..read(sosServiceProvider)
      ..read(speechServiceProvider)
      ..read(modelManagerProvider);
  });
}
