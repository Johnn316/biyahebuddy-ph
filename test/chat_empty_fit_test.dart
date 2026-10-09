// Buddy empty state: the topic tiles are never hidden behind the frosted
// input bar — scrolled to the end, the last tile is fully above it.
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
      testWidgets(
        '$name phone, ${brightness.name}: topics clear of the input',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
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

          // Scroll to the end: the last tile is fully above the input bar.
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
          final last = find.byKey(const Key('topic-coding'));
          expect(last.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(last).bottom,
            lessThanOrEqualTo(inputTop),
            reason: 'last topic hidden behind the input bar',
          );
          // Tiles: 2 per row on phones.
          final a = tester.getRect(find.byKey(const Key('topic-signs')));
          final b = tester.getRect(find.byKey(const Key('topic-markings')));
          expect(a.top, b.top);
        },
      );
    }
  }
}
