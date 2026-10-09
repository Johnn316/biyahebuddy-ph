// Home must show SOS, both pills and both shortcut rows above the floating
// tab bar — no scrolling needed — on real phone/tablet sizes with system
// insets, at normal and enlarged font.
import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$w.ttf'));
    }
    await loader.load();
  });

  const sizes = {
    'small phone': Size(360, 640),
    'phone': Size(393, 852),
    'large phone': Size(412, 915),
    'tablet portrait': Size(800, 1280),
    'tablet landscape': Size(1280, 800),
  };

  for (final scale in [1.0, 1.3]) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('$name ${scale}x: everything above the tab bar', (
        tester,
      ) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileRepositoryProvider.overrideWithValue(
                MemoryProfileRepository(FakeProfileRepository.sample),
              ),
              codingServiceProvider.overrideWithValue(
                const FixedCodingService(isCoding: true),
              ),
            ],
            child: const App(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final tabTop = tester.getRect(find.byKey(const Key('tab-home'))).top;
        for (final key in [
          'home-emergency',
          'home-share-location',
          'home-qr',
          'home-chat',
          'home-violation',
        ]) {
          final f = find.byKey(Key(key));
          expect(f.hitTestable(), findsOneWidget, reason: key);
          expect(tester.getRect(f).bottom, lessThan(tabTop), reason: key);
        }
        // SOS stays a real hero on phones and tablets at normal font.
        if (scale == 1.0) {
          final sos = tester.getSize(find.byKey(const Key('home-emergency')));
          expect(sos.width, greaterThanOrEqualTo(120));
        }
      });
    }
  }
}
