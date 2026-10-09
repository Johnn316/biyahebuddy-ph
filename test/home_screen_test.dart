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

String chatInput(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('chat-input')))
    .controller!
    .text;

void main() {
  testWidgets('Home dashboard: top bar, vehicle, Ask hero, cards, SOS bar', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);

    // Top bar: app mark + initials avatar.
    expect(find.text('BiyaheBuddy PH'), findsOneWidget);
    expect(find.text('JD'), findsOneWidget);
    // Sasakyan mo: plate, vehicle, one status line.
    expect(find.text('SASAKYAN MO'), findsOneWidget);
    expect(find.text('NAB 1234'), findsOneWidget);
    expect(find.text('Kotse'), findsOneWidget);
    expect(find.text('Hindi coding'), findsOneWidget);
    expect(find.text('I-download si Buddy'), findsOneWidget); // fakes
    // Hero.
    expect(find.text('Tanong kay Buddy'), findsOneWidget);
    expect(find.text("Ano'ng tanong mo sa batas trapiko?"), findsOneWidget);
    for (final t in ['Multa', 'Helmet', 'Overtaking']) {
      expect(find.text(t), findsOneWidget);
    }
    // Two cards.
    expect(find.text('Na-flag ako'), findsOneWidget);
    expect(find.text('Alamin ang tamang multa'), findsOneWidget);
    expect(find.text('TIP NG ARAW'), findsOneWidget);
    // SOS bar; no QR / Lokasyon tiles, no big profile card.
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Naaksidente ako'), findsOneWidget);
    expect(find.byKey(const Key('home-qr')), findsNothing);
    expect(find.byKey(const Key('home-share-location')), findsNothing);
    expect(find.byKey(const Key('home-profile-card')), findsNothing);
    for (final t in ['Home', 'Na-flag', 'Profile']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('SOS bar: full width, compact, just above the tab bar', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    final sos = tester.getRect(find.byKey(const Key('home-emergency')));
    expect(sos.width, greaterThan(412 - 2 * 16 - 1));
    expect(sos.height, greaterThanOrEqualTo(64)); // real-font height: fit test
    final tabTop = tester.getRect(find.byKey(const Key('tab-home'))).top;
    expect(sos.bottom, lessThan(tabTop));
    expect(find.byKey(const Key('sos-pulse')), findsOneWidget);
  });

  testWidgets('cards fill the screen: no dead space above the SOS bar', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    final cards = tester.getRect(find.byKey(const Key('home-violation')));
    final sos = tester.getRect(find.byKey(const Key('home-emergency')));
    expect(sos.top - cards.bottom, lessThan(40));
    final tip = tester.getRect(find.byKey(const Key('home-tip')));
    expect(tip.height, cards.height); // two equal cards
    expect(tip.top, cards.top);
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
    testWidgets('coding status is AMBER, never red ($brightness)', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpHome(tester, isCoding: true);
      expect(find.text('Coding ngayon'), findsOneWidget);
      final palette = brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
      final chip = find.byKey(const Key('coding-badge'));
      final icon = tester.widget<Icon>(
        find.descendant(of: chip, matching: find.byType(Icon)),
      );
      final text = tester.widget<Text>(
        find.descendant(of: chip, matching: find.byType(Text)),
      );
      expect(icon.color, palette.cautionText);
      expect(text.style!.color, palette.cautionText);
      expect(icon.color, isNot(palette.emergency));
    });
  }

  testWidgets('SOS pulse dot is static under reduce motion', (tester) async {
    await pumpHome(tester, isCoding: false); // reduce motion on (test config)
    final dot = tester.widget<FadeTransition>(
      find.byKey(const Key('sos-pulse')),
    );
    final v = dot.opacity.value;
    await tester.pump(const Duration(milliseconds: 800));
    expect(dot.opacity.value, v);
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

  testWidgets('Ask field opens Buddy with the keyboard; chips prefill', (
    tester,
  ) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-chat');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(field.focusNode!.hasFocus, isTrue);

    await tapKey(tester, 'tab-home');
    await tapKey(tester, 'topic-helmet');
    expect(chatInput(tester), 'Ano ang multa kapag walang helmet?');
  });

  testWidgets('tapping the tip asks Buddy about that law', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-tip');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    expect(chatInput(tester), startsWith('Ipaliwanag ang RA '));
  });

  testWidgets('avatar and vehicle card open Profile', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-avatar');
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('NAB 1234'), findsOneWidget); // prefilled field
    await tapKey(tester, 'tab-home');
    await tapKey(tester, 'home-vehicle');
    expect(find.text('Profile'), findsWidgets);
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

  testWidgets('Na-flag card and tab bar switch tabs', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tapKey(tester, 'home-violation');
    expect(find.text("Sino ang nag-flag sa'yo?"), findsOneWidget);
    await tapKey(tester, 'tab-profile');
    expect(find.text('Profile'), findsWidgets);
    await tapKey(tester, 'tab-chat');
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    await tapKey(tester, 'tab-home');
    expect(find.text('SOS'), findsOneWidget);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('small phone + ${scale}x font: no overflow, SOS visible', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpHome(tester, isCoding: true);
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home-emergency')).hitTestable(), findsOne);
      // Everything reachable by scrolling the middle.
      await tester.dragUntilVisible(
        find.byKey(const Key('home-tip')),
        find.byKey(const Key('home-scroll')),
        const Offset(0, -200),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
