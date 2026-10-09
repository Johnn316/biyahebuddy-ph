import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/core/theme/app_theme.dart';
import 'package:biyahebuddy_ph/features/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> pumpHome(WidgetTester tester, {required bool isCoding}) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(FakeProfileRepository.sample),
        ),
        codingServiceProvider.overrideWithValue(
          FixedCodingService(isCoding: isCoding),
        ),
        sosServiceProvider.overrideWithValue(RecordingSosService()),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home dashboard: greeting, chips, SOS, 2x2 actions, tip', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);

    expect(
      find.textContaining(RegExp(r'^Magandang .+, Juan$')),
      findsOneWidget,
    );
    expect(find.text('NAB 1234 · Kotse'), findsOneWidget);
    expect(find.text('Hindi ka coding'), findsOneWidget);
    expect(
      find.bySemanticsLabel('MMDA coding: Hindi ka coding'),
      findsOneWidget,
    );
    // Fakes: models not downloaded yet; GPS from the recording SOS fake.
    expect(find.text('I-download si Buddy'), findsOneWidget);
    expect(find.text('GPS handa'), findsOneWidget);
    expect(find.text('TIP NG ARAW'), findsOneWidget); // tall phone: tip shown
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Pindutin kapag naaksidente'), findsOneWidget);
    expect(find.text('Ibahagi lokasyon'), findsOneWidget);
    expect(find.text('QR Exchange'), findsOneWidget);
    expect(find.text('Tanong kay Buddy'), findsOneWidget);
    expect(find.text('Na-flag ako'), findsOneWidget);
    // Floating tab bar.
    for (final t in ['Home', 'Buddy', 'Na-flag', 'Profile']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  test('greeting by time of day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 7)), 'Magandang umaga');
    expect(greetingFor(DateTime(2026, 1, 1, 13)), 'Magandang hapon');
    expect(greetingFor(DateTime(2026, 1, 1, 20)), 'Magandang gabi');
  });

  for (final brightness in Brightness.values) {
    testWidgets('coding pill is AMBER, never red ($brightness)', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpHome(tester, isCoding: true);
      expect(find.text('Coding ka ngayon'), findsOneWidget);
      final palette = brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
      // Amber tint + amber icon/text — never the SOS red.
      final chip = find.byKey(const Key('coding-badge'));
      final box = tester.widget<AnimatedContainer>(
        find.descendant(of: chip, matching: find.byType(AnimatedContainer)),
      );
      final bg = (box.decoration! as BoxDecoration).color;
      final icon = tester.widget<Icon>(
        find.descendant(of: chip, matching: find.byType(Icon)),
      );
      expect(bg, palette.cautionTint);
      expect(icon.color, palette.cautionText);
      for (final c in [bg, icon.color]) {
        expect(c, isNot(palette.emergency));
        expect(c, isNot(palette.emergencyDeep));
      }
    });
  }

  testWidgets('SOS is the biggest thing on Home (a circle)', (tester) async {
    await pumpHome(tester, isCoding: false);
    final sos = tester.getSize(find.byKey(const Key('home-emergency')));
    expect(sos.width, sos.height); // circle
    expect(sos.width, greaterThan(412 * 0.4));
    final tile = tester.getSize(find.byKey(const Key('home-chat')));
    expect(sos.height, greaterThan(tile.height));
  });

  testWidgets('SOS glow breathes, and is static under reduce motion', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
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
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    BoxShadow glow() =>
        ((tester
                        .widget<DecoratedBox>(find.byKey(const Key('sos-glow')))
                        .decoration
                    as BoxDecoration)
                .boxShadow!)
            .single;
    final before = glow();
    await tester.pump(const Duration(milliseconds: 600));
    expect(glow(), isNot(before)); // breathing

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    final still = glow();
    await tester.pump(const Duration(milliseconds: 600));
    expect(glow(), still); // reduce motion: static
    expect(still.color.a, closeTo(0.45, 0.01));
    await tester.pumpWidget(const SizedBox()); // stop tickers
  });

  test('tip of the day skips boilerplate and is stable within a day', () {
    final laws = [
      {
        'id': 'x-s1',
        'source': 'RA 1 (X)',
        'section': 'Sec. 1',
        'title': 'Short Title',
        'text': 'a' * 200,
      },
      {
        'id': 'x-s2',
        'source': 'RA 1 (X)',
        'section': 'Sec. 2',
        'title': 'Right of way',
        'text': 'b' * 200,
      },
      {
        'id': 'x-s3-p1',
        'source': 'RA 1 (X)',
        'section': 'Sec. 3',
        'title': 'Speed',
        'text': 'c' * 200,
      },
    ];
    final tip = pickTip(laws, DateTime(2026, 10, 10, 8))!;
    expect(tip.title, 'Right of way');
    expect(tip.citation, 'RA 1 Sec. 2');
    expect(pickTip(laws, DateTime(2026, 10, 10, 23))!.title, tip.title);
  });

  testWidgets('tapping the tip asks Buddy about that law', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-tip');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    final input = tester.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(input.controller!.text, startsWith('Ipaliwanag ang RA '));
  });

  testWidgets('SOS opens Emergency in one tap (no dialog); back returns', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-emergency');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Ligtas ka ba?'), findsOneWidget);
    expect(find.text('Home'), findsNothing); // full screen, above tab bar
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('shortcut rows and tab bar switch tabs', (tester) async {
    await pumpHome(tester, isCoding: false);

    await tapKey(tester, 'home-chat');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    await tapKey(tester, 'tab-home');
    expect(find.text('SOS'), findsOneWidget);

    await tapKey(tester, 'home-violation');
    expect(find.text("Sino ang nag-flag sa'yo?"), findsOneWidget);

    await tapKey(tester, 'tab-profile');
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('NAB 1234'), findsOneWidget); // prefilled field

    await tapKey(tester, 'tab-chat');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
  });

  testWidgets('"Ibahagi lokasyon" opens Emergency at the contacts', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-share-location');
    expect(find.byKey(const Key('text-all')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('call-contact-0')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('"QR Exchange" pill opens the full-screen QR', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-qr');
    expect(find.text('Ipa-scan sa kabilang driver'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('small phone + 1.5x system font: no overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpHome(tester, isCoding: true);
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('home-emergency'))).height,
      greaterThan(120),
    );
  });
}
