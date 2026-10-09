import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> pumpApp(WidgetTester tester) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(FakeProfileRepository.sample),
        ),
        codingServiceProvider.overrideWithValue(
          const FixedCodingService(isCoding: false),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

Brightness appBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  testWidgets('defaults to System; Profile switch changes + persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(appBrightness(tester), Brightness.light); // follows system

    await tester.tap(find.byKey(const Key('tab-profile')));
    await tester.pumpAndSettle();
    expect(find.text('ITSURA'), findsOneWidget);
    expect(find.text('Light'), findsNothing); // hidden while following system

    // Turn off "Sundin ang system" → Light/Dark control appears.
    await tester.tap(find.byKey(const Key('theme-follow-system')));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(appBrightness(tester), Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeModeController.prefsKey), 'dark');

    // Back to System.
    await tester.tap(find.byKey(const Key('theme-follow-system')));
    await tester.pumpAndSettle();
    expect(appBrightness(tester), Brightness.light);
    expect(prefs.getString(ThemeModeController.prefsKey), 'system');
  });

  testWidgets('saved choice is restored on launch', (tester) async {
    SharedPreferences.setMockInitialValues({
      ThemeModeController.prefsKey: 'dark',
    });
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(appBrightness(tester), Brightness.dark);
  });
}
