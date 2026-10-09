// Visits every screen in light + dark, at normal and largest (2.0x) font,
// on a small and a regular phone, and fails on any overflow/exception.
import 'dart:async';

import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Real font metrics (the default test font draws every glyph as a square).
Future<void> _loadAppFont() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$w.ttf'));
  }
  await loader.load();
}

typedef _Combo = ({Brightness brightness, double scale, Size size});

final _combos = <_Combo>[
  for (final b in Brightness.values)
    for (final scale in [1.0, 2.0])
      for (final size in const [Size(360, 640), Size(412, 915)])
        (brightness: b, scale: scale, size: size),
];

String _name(_Combo c) =>
    '${c.brightness.name} · ${c.scale}x · '
    '${c.size.width.toInt()}x${c.size.height.toInt()}';

Future<GoRouterHelper> _pump(
  WidgetTester tester,
  _Combo c, {
  bool withProfile = true,
}) async {
  tester.view.physicalSize = c.size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = c.brightness;
  tester.platformDispatcher.textScaleFactorTestValue = c.scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  SharedPreferences.setMockInitialValues({});

  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(
            withProfile ? FakeProfileRepository.sample : null,
          ),
        ),
        codingServiceProvider.overrideWithValue(
          const FixedCodingService(isCoding: true),
        ),
        aiAssistantProvider.overrideWithValue(
          FakeAiAssistant(tokenDelay: Duration.zero),
        ),
        sosServiceProvider.overrideWithValue(RecordingSosService()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return const App();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return GoRouterHelper(tester, container);
}

class GoRouterHelper {
  GoRouterHelper(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  Future<void> push(String location) async {
    unawaited(container.read(routerProvider).push(location));
    await settle();
  }

  Future<void> settle() async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> tap(String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await settle();
    await tester.tap(f);
    await settle();
  }

  /// Scrolls the main list to the end, checking for overflow on the way.
  Future<void> scrollThrough() async {
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await settle();
    }
  }
}

void main() {
  setUpAll(_loadAppFont);

  for (final c in _combos) {
    group(_name(c), () {
      testWidgets('Home + Profile', (tester) async {
        final app = await _pump(tester, c);
        expect(find.text('EMERGENCY'), findsOneWidget);
        await app.push(Routes.profile);
        await app.scrollThrough();
      });

      testWidgets('Onboarding: download + form', (tester) async {
        final app = await _pump(tester, c, withProfile: false);
        expect(find.byKey(const Key('model-download')), findsOneWidget);
        await app.tap('model-download');
        await tester.pump(const Duration(seconds: 4));
        await app.settle();
        await app.tap('model-continue');
        await app.scrollThrough();
      });

      testWidgets('Emergency + QR', (tester) async {
        final app = await _pump(tester, c);
        await app.push(Routes.emergency);
        await app.tap('injured-yes');
        await app.scrollThrough();
        await app.tap('open-qr');
        expect(find.text('Ipa-scan sa kabilang driver'), findsOneWidget);
      });

      testWidgets('Na-flag ako → result → IPAKITA (+ landscape)', (
        tester,
      ) async {
        final app = await _pump(tester, c);
        await app.push(Routes.violation);
        await app.tap('agency-mmda');
        await app.tap('fine-0');
        await app.scrollThrough();
        await app.tap('ipakita');
        tester.view.physicalSize = Size(c.size.height, c.size.width) * 2;
        await app.settle();
      });

      testWidgets('Chat: empty, answer, Dalawang panig', (tester) async {
        final app = await _pump(tester, c);
        await app.push(Routes.chat);
        await tester.enterText(
          find.byKey(const Key('chat-input')),
          'Nabangga ako, sino may mali?',
        );
        await app.settle();
        await app.tap('chat-send');
        expect(find.text('Ano ang sinasabi ng batas'), findsOneWidget);
        await app.scrollThrough();
        await tester.tap(find.text('Dalawang panig'));
        await app.settle();
        expect(find.text('Ano ang nangyari sa panig mo?'), findsOneWidget);
      });
    });
  }
}
