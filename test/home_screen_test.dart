import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
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
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saved profile → Home with all main actions', (tester) async {
    await pumpHome(tester, isCoding: false);

    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.text('Naaksidente ako'), findsOneWidget);
    expect(find.text('Tanong kay\nBuddy'), findsOneWidget);
    expect(find.text('Na-flag\nako'), findsOneWidget);
    expect(find.text('MMDA coding'), findsOneWidget);
    expect(find.text('NAB 1234'), findsOneWidget);
    expect(find.text('Hindi ka coding'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('coding day shows red "Coding ka ngayon"', (tester) async {
    await pumpHome(tester, isCoding: true);
    expect(find.text('Coding ka ngayon'), findsOneWidget);
  });

  testWidgets('emergency is the largest button', (tester) async {
    await pumpHome(tester, isCoding: false);
    final emergency = tester.getSize(find.byKey(const Key('home-emergency')));
    final chat = tester.getSize(find.byKey(const Key('home-chat')));
    final flagged = tester.getSize(find.byKey(const Key('home-violation')));
    expect(emergency.height, greaterThan(chat.height));
    expect(chat, flagged); // two equal buttons
  });

  testWidgets('buttons navigate and back returns home', (tester) async {
    await pumpHome(tester, isCoding: false);

    for (final (key, title) in [
      ('home-emergency', 'Emergency'),
      ('home-chat', 'Tanong kay Buddy'),
      ('home-violation', 'Na-flag ako'),
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('EMERGENCY'), findsOneWidget);
    }
  });

  testWidgets('small phone (360x640): no overflow', (tester) async {
    await pumpHome(tester, isCoding: true);
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('EMERGENCY'), findsOneWidget);
  });

  testWidgets('profile icon opens prefilled profile', (tester) async {
    await pumpHome(tester, isCoding: false);
    await tester.tap(find.byKey(const Key('home-profile')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('NAB 1234'), findsOneWidget);
  });
}
