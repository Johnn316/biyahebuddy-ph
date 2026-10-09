// Buddy empty state: the 4 suggestion cards are never hidden behind the
// frosted input bar. Normal phones: everything fits without scrolling.
// Small phones: it scrolls, and the last card can be scrolled clear.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_screen_test.dart' show ControlledAi, pumpChat;

void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$w.ttf'));
    }
    await loader.load();
  });

  const sizes = {'small': Size(360, 640), 'normal': Size(412, 915)};
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('$name phone, ${brightness.name}: cards clear of the input', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
        await pumpChat(tester, ai: ControlledAi(), logicalSize: size);
        expect(tester.takeException(), isNull);

        final inputTop = tester
            .getRect(find.byKey(const Key('chat-input')))
            .top;
        final scrollable = find.descendant(
          of: find.byKey(const Key('chat-empty')),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;

        if (name == 'normal') {
          // Everything fits: no scrolling, all 4 cards above the input.
          expect(position.maxScrollExtent, 0);
        } else {
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
        }
        for (var i = 0; i < 4; i++) {
          final card = find.byKey(Key('quick-$i'));
          if (name == 'normal' || i == 3) {
            expect(card.hitTestable(), findsOneWidget, reason: 'quick-$i');
            expect(
              tester.getRect(card).bottom,
              lessThanOrEqualTo(inputTop),
              reason: 'quick-$i hidden behind the input bar',
            );
          }
        }
        // Card text: at most 2 lines.
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('quick-1')),
            matching: find.byType(Text),
          ),
        );
        expect(text.maxLines, 2);
      });
    }
  }
}
