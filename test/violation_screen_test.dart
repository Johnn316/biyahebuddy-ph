import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/config/features.dart';
import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/features/violation/controllers/violation_controller.dart';
import 'package:biyahebuddy_ph/core/theme/app_theme.dart';
import 'package:biyahebuddy_ph/features/violation/screens/officer_message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _ScriptedSpeech implements SpeechService {
  _ScriptedSpeech(this.transcript);

  final String transcript;
  int starts = 0;

  @override
  Future<void> startListening() async => starts++;

  @override
  Future<String> stopAndTranscribe() async => transcript;
}

/// Home → tap "Na-flag ako".
Future<void> openViolation(
  WidgetTester tester, {
  Size logicalSize = const Size(412, 915),
  SpeechService? speech,
}) async {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(FakeProfileRepository.sample),
        ),
        codingServiceProvider.overrideWithValue(
          const FixedCodingService(isCoding: false),
        ),
        speechServiceProvider.overrideWithValue(
          speech ?? _ScriptedSpeech('seatbelt'),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('tab-violation')));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('2 taps to the answer: agency → violation → result card', (
    tester,
  ) async {
    await openViolation(tester);

    expect(find.text("Sino ang nag-flag sa'yo?"), findsOneWidget);
    expect(find.byKey(const Key('violation-search')), findsNothing);

    await tapKey(tester, 'agency-lto'); // tap 1
    expect(find.text('KARANIWANG VIOLATION'), findsOneWidget);
    expect(find.text('Driving without a valid license'), findsOneWidget);
    // Only LTO violations.
    expect(find.text('Number coding (UVVRP) violation'), findsNothing);

    await tapKey(tester, 'fine-0'); // tap 2
    expect(find.text('Driving without a valid license'), findsOneWidget);
    expect(find.text('₱3,000'), findsOneWidget);
    expect(find.text('SAMPLE — LTO JAO 2014-01'), findsOneWidget);
    expect(
      find.text(
        'Humingi ng official ticket. Huwag magbayad on the spot nang walang '
        'resibo.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ipakita')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search filters by text and agency chips switch lists', (
    tester,
  ) async {
    await openViolation(tester);
    await tapKey(tester, 'agency-lto');

    await tester.enterText(find.byKey(const Key('violation-search')), 'cell');
    await tester.pumpAndSettle();
    expect(find.text('RESULTA'), findsOneWidget);
    expect(find.text('Using mobile phone while driving'), findsOneWidget);
    expect(find.text('Driving without a valid license'), findsNothing);

    await tester.enterText(find.byKey(const Key('violation-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Walang nahanap'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('violation-search')), '');
    await tapKey(tester, 'agency-chip-mmda');
    expect(find.text('Number coding (UVVRP) violation'), findsOneWidget);
    expect(find.text('Driving without a valid license'), findsNothing);
  });

  testWidgets('no mic on the search when voice input is disabled', (
    tester,
  ) async {
    await openViolation(tester, speech: FakeSpeechService());
    await tapKey(tester, 'agency-lto');
    expect(find.byKey(const Key('violation-search')), findsOneWidget);
    expect(find.byKey(const Key('mic')), findsNothing);
  }, skip: kVoiceInputEnabled);

  testWidgets('mic: tap to listen, tap again → transcript fills search', (
    tester,
  ) async {
    final speech = _ScriptedSpeech('seatbelt');
    await openViolation(tester, speech: speech);
    await tapKey(tester, 'agency-lto');

    await tapKey(tester, 'mic');
    expect(speech.starts, 1);
    expect(find.text('Nakikinig… (pindutin ulit)'), findsOneWidget);

    await tapKey(tester, 'mic');
    final field = tester.widget<TextField>(
      find.byKey(const Key('violation-search')),
    );
    expect(field.controller!.text, 'seatbelt');
    expect(
      find.text('Failure to wear seatbelt (driver, 1st offense)'),
      findsOneWidget,
    );
  }, skip: !kVoiceInputEnabled);

  testWidgets('spoken sentence still finds the violation (fake speech)', (
    tester,
  ) async {
    // Default FakeSpeechService returns a full Taglish sentence.
    await openViolation(tester, speech: FakeSpeechService());
    await tapKey(tester, 'agency-mmda');
    await tapKey(tester, 'mic');
    await tester.tap(find.byKey(const Key('mic')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Disregarding traffic signs'), findsOneWidget);
  }, skip: !kVoiceInputEnabled);

  testWidgets('IPAKITA → full-screen officer message → Tapos na', (
    tester,
  ) async {
    await openViolation(tester);
    await tapKey(tester, 'agency-mmda');
    await tapKey(tester, 'fine-0');
    await tapKey(tester, 'ipakita');

    expect(find.text('Magandang araw po.'), findsOneWidget);
    expect(find.text('Disregarding traffic signs'), findsWidgets);
    expect(find.text('₱1,000'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Landscape still fits.
    tester.view.physicalSize = const Size(1830, 824);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapKey(tester, 'officer-done');
    expect(find.byKey(const Key('ipakita')), findsOneWidget);
  });

  testWidgets('back from result keeps the selected agency', (tester) async {
    await openViolation(tester);
    await tapKey(tester, 'agency-city');
    await tapKey(tester, 'fine-0');
    expect(find.byKey(const Key('ipakita')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Illegal parking (attended)'), findsOneWidget);
    final cityChip = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('agency-chip-city')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(cityChip.properties.selected, isTrue);

    // Back again → step 1 (agency picker); then the Home tab.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text("Sino ang nag-flag sa'yo?"), findsOneWidget);
    expect(find.byType(BackButton), findsNothing); // tab root
    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('"Hindi ko alam" opens Buddy with the question prefilled', (
    tester,
  ) async {
    await openViolation(tester);
    await tapKey(tester, 'agency-city');
    await tapKey(tester, 'unknown-violation');

    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    final input = tester.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(
      input.controller!.text,
      'Na-flag ako ng city enforcer, ano ang posibleng violation?',
    );
  });

  testWidgets('small phone 360x640: step 1 and step 2 fit', (tester) async {
    await openViolation(tester, logicalSize: const Size(360, 640));
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'agency-lto');
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('unknown-violation')).hitTestable(),
      findsOneWidget,
    );
  });

  test('formatPeso', () {
    expect(formatPeso(150), '₱150');
    expect(formatPeso(1000), '₱1,000');
    expect(formatPeso(1234567), '₱1,234,567');
    expect(formatPeso(1500.5), '₱1,500.50');
  });

  group('IPAKITA layout', () {
    setUpAll(() async {
      final loader = FontLoader('PlusJakartaSans');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
        loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$w.ttf'));
      }
      await loader.load();
    });

    const fine = Fine(
      violation: 'Disregarding traffic signs (incl. beating the red light)',
      agency: Agency.mmda,
      amount: 1000,
      legalBasis:
          'Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023), '
          'Sec. 10, as implemented by MMDA Regulation No. 23-002',
    );

    const sizes = {
      'small portrait': Size(360, 640),
      'small landscape': Size(640, 360),
      'phone portrait': Size(412, 915),
      'phone landscape': Size(915, 412),
    };
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('$name: full width, words never split, no scroll', (
        tester,
      ) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const OfficerMessageScreen(fine: fine),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Text uses the full width (24dp sides), not a narrow column.
        final line = tester.getRect(find.byKey(const Key('officer-line-1')));
        expect(line.width, closeTo(size.width - 48, 1));

        // Lines wrap only at spaces.
        for (var i = 0; i < 5; i++) {
          final para = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(Key('officer-line-$i')),
              matching: find.byType(RichText),
            ),
          );
          final text = para.text.toPlainText();
          final painter = TextPainter(
            text: para.text,
            textAlign: para.textAlign,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: para.size.width);
          addTearDown(painter.dispose);
          var offset = 0;
          while (offset < text.length) {
            final end = painter
                .getLineBoundary(TextPosition(offset: offset))
                .end;
            if (end >= text.length || end <= offset) break;
            final atSpace = text[end - 1] == ' ' || text[end] == ' ';
            expect(atSpace, isTrue, reason: 'line $i breaks at "$text"@$end');
            offset = end;
          }
        }

        // Fits without scrolling; base ≥ 22 in portrait.
        final scroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('officer-message')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scroll.position.maxScrollExtent, 0);
        final greeting = tester.widget<Text>(
          find.byKey(const Key('officer-line-0')),
        );
        if (size.height > size.width) {
          expect(greeting.style!.fontSize, greaterThanOrEqualTo(22));
        }
        // Fine amount is the biggest, in amber.
        final amount = tester.widget<Text>(
          find.byKey(const Key('officer-line-2')),
        );
        expect(amount.style!.fontSize, greaterThan(greeting.style!.fontSize!));
        expect(amount.style!.color, AppPalette.dark.accent);
      });
    }
  });
}
