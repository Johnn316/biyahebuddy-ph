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

    // Profile card: greeting, name, plate badge, vehicle, chips.
    expect(
      find.textContaining(RegExp(r'^Magandang (umaga|hapon|gabi)$')),
      findsOneWidget,
    );
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('NAB 1234'), findsOneWidget);
    expect(find.text('Kotse'), findsOneWidget);
    expect(find.text('Hindi coding'), findsOneWidget);
    // The card is one button; screen readers read its chips as part of it.
    expect(
      find.bySemanticsLabel(RegExp('MMDA coding: Hindi ka coding')),
      findsOneWidget,
    );
    // Fakes: models not downloaded yet; GPS from the recording SOS fake
    // (icon-only chip, so its meaning is in the semantics label).
    expect(find.text('I-download si Buddy'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('GPS handa')), findsOneWidget);
    // GPS chip: map pin + word, green when ready (not an icon-only chip).
    expect(find.text('GPS'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Pindutin kapag naaksidente'), findsOneWidget);
    // Short tile labels; full names for screen readers.
    expect(find.text('AI Buddy'), findsOneWidget); // first tile
    // Brand row: this is an AI driving buddy.
    expect(find.text('BiyaheBuddy PH'), findsOneWidget);
    expect(find.byKey(const Key('ai-badge')), findsOneWidget);
    expect(find.text('AI Driving Buddy'), findsOneWidget);
    expect(
      find.text('Ang AI driving buddy mo — kahit walang signal'),
      findsNothing,
    );
    expect(find.text('Na-flag ako'), findsOneWidget);
    expect(find.text('QR'), findsOneWidget);
    expect(find.text('Lokasyon'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^AI Buddy')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Ibahagi lokasyon')), findsOneWidget);
    // Floating tab bar.
    for (final t in ['Home', 'Na-flag', 'Profile']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  test('greeting by time of day', () {
    String at(int h, [int m = 0]) => greetingFor(DateTime(2026, 1, 1, h, m));
    expect(at(0), 'Magandang gabi');
    expect(at(3, 59), 'Magandang gabi');
    expect(at(4), 'Magandang umaga');
    expect(at(11, 59), 'Magandang umaga');
    expect(at(12), 'Magandang hapon');
    expect(at(17, 59), 'Magandang hapon');
    expect(at(18), 'Magandang gabi');
    expect(at(23, 59), 'Magandang gabi');
  });

  for (final brightness in Brightness.values) {
    testWidgets('coding pill is AMBER, never red ($brightness)', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpHome(tester, isCoding: true);
      expect(find.text('Coding ngayon'), findsOneWidget);
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
    expect(sos.width, greaterThan(412 * 0.6)); // ~65–70% of the screen
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

  testWidgets('tapping the tip asks Buddy about that law (tablet)', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    tester.view.physicalSize = const Size(1600, 2560);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle();
    expect(find.text('TIP NG ARAW'), findsOneWidget);
    await tapKey(tester, 'home-tip');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    final input = tester.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(input.controller!.text, startsWith('Ipaliwanag ang RA '));
  });

  testWidgets('profile card opens Profile', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-profile-card');
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('NAB 1234'), findsOneWidget); // prefilled field
  });

  testWidgets('status chips stay in one row at the largest font', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpHome(tester, isCoding: true);
    final coding = tester.getRect(find.byKey(const Key('coding-badge')));
    final offline = tester.getRect(find.byKey(const Key('offline-badge')));
    final gps = tester.getRect(find.byKey(const Key('gps-chip')));
    expect(offline.center.dy, closeTo(coding.center.dy, 1));
    expect(gps.center.dy, closeTo(coding.center.dy, 1));
    final card = tester.getRect(find.byKey(const Key('home-profile-card')));
    expect(gps.right, lessThanOrEqualTo(card.right));
    expect(tester.takeException(), isNull);
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
