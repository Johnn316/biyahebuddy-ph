// Home must show the whole dashboard above the floating tab bar — no
// scrolling needed — on real phone/tablet sizes with system insets; the SOS
// bar is always pinned right above the tab bar.
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
        // SOS bar always visible, right above the tab bar.
        final sos = tester.getRect(find.byKey(const Key('home-emergency')));
        expect(sos.bottom, lessThan(tabTop));
        expect(tabTop - sos.bottom, lessThan(24));
        // Compact bar (~64dp) at normal text.
        if (scale == 1.0) expect(sos.height, lessThan(72));
        // Everything else fits without scrolling (except the smallest phone
        // at enlarged text, where the middle scrolls).
        if (scale == 1.0 || size.height >= 800) {
          for (final key in [
            'home-avatar',
            'home-vehicle',
            'home-chat',
            'home-violation',
            'home-tip',
            'home-emergency',
          ]) {
            final f = find.byKey(Key(key));
            expect(f.hitTestable(), findsOneWidget, reason: key);
            expect(tester.getRect(f).bottom, lessThan(tabTop), reason: key);
          }
        }
      });
    }
  }
}
