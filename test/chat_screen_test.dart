import 'dart:async';

import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/core/router/app_router.dart';
import 'package:biyahebuddy_ph/features/chat/controllers/answer_format.dart';
import 'package:biyahebuddy_ph/features/chat/widgets/buddy_answer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// AI whose stream the test drives chunk by chunk.
class ControlledAi implements AiAssistant {
  final asked = <String>[];
  final twoSides = <(String, String)>[];
  StreamController<String>? current;

  @override
  Stream<String> ask(String question) {
    asked.add(question);
    return (current = StreamController<String>()).stream;
  }

  @override
  Stream<String> analyzeTwoSides(String a, String b) {
    twoSides.add((a, b));
    return (current = StreamController<String>()).stream;
  }

  void emit(String chunk) => current!.add(chunk);
  Future<void> finish() => current!.close();
}

class _ScriptedSpeech implements SpeechService {
  @override
  Future<void> startListening() async {}

  @override
  Future<String> stopAndTranscribe() async => 'Pwede ba mag-U-turn dito?';
}

const _answer =
    '**Kalma muna**\nHuwag mag-alala.\n\n'
    '**Ano ang sinasabi ng batas**\nAng naunang pumasok ang may right of way '
    '(RA 4136 Sec. 42).\n\n'
    '**Pagsusuri**\nMukhang ikaw ang nauna.\n\n'
    '**Ano ang gagawin**\n1. Kunan ng litrato.';

Future<void> pumpChat(
  WidgetTester tester, {
  required AiAssistant ai,
  String location = '/chat',
  Size logicalSize = const Size(412, 915),
}) async {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          MemoryProfileRepository(FakeProfileRepository.sample),
        ),
        codingServiceProvider.overrideWithValue(
          const FixedCodingService(isCoding: false),
        ),
        aiAssistantProvider.overrideWithValue(ai),
        speechServiceProvider.overrideWithValue(_ScriptedSpeech()),
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
  // Open from Home with push so Back returns to Home.
  final router = container.read(routerProvider);
  unawaited(router.push(location));
  await tester.pumpAndSettle();
}

Future<void> typeAndSend(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('chat-input')), text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('chat-send')));
  await tester.pump();
}

String inputText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('chat-input')))
    .controller!
    .text;

void main() {
  testWidgets('header, empty state, quick chips; ?q= prefills, no auto-send', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(
      tester,
      ai: ai,
      location: '/chat?q=${Uri.encodeQueryComponent('Na-flag ako ng LTO')}',
    );

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Gumagana kahit walang signal'), findsOneWidget);
    expect(find.text('Magkano multa sa…'), findsOneWidget);
    expect(
      find.text('Nabangga ako, sino may mali?', skipOffstage: false),
      findsOneWidget,
    );
    expect(inputText(tester), 'Na-flag ako ng LTO');
    expect(ai.asked, isEmpty); // not auto-sent
    expect(tester.takeException(), isNull);
  });

  testWidgets('streams token by token into 4 sections with citation chip', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Sino ang may right of way?');

    expect(ai.asked, ['Sino ang may right of way?']);
    expect(find.text('Sino ang may right of way?'), findsOneWidget);
    expect(find.text('Magkano multa sa…'), findsNothing); // chips gone
    expect(find.text('Nag-iisip si Buddy…'), findsOneWidget);
    // Streaming: send replaced by stop.
    expect(find.byKey(const Key('chat-send')), findsNothing);
    expect(find.byKey(const Key('chat-stop')), findsOneWidget);

    // User bubble is on the right half, Buddy on the left.
    final userX = tester.getCenter(find.text('Sino ang may right of way?')).dx;
    expect(userX, greaterThan(412 / 2));

    for (final word in _answer.split(' ')) {
      ai.emit('$word ');
      await tester.pump();
    }
    expect(find.byKey(const Key('section-kalma')), findsOneWidget);
    expect(find.byKey(const Key('chat-stop')), findsOneWidget); // still going

    await ai.finish();
    await tester.pumpAndSettle();

    for (final kind in AnswerSectionKind.values) {
      expect(find.text(kind.label), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('citation-RA 4136 Sec. 42')),
      findsOneWidget,
    );
    expect(find.text(answerDisclaimer), findsOneWidget);
    expect(find.byKey(const Key('chat-stop')), findsNothing);
    expect(find.byKey(const Key('chat-send')), findsOneWidget);
    expect(tester.getCenter(find.text('Buddy').last).dx, lessThan(412 / 2));
  });

  testWidgets('stop mid-stream keeps partial answer and re-enables send', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Tanong');
    ai.emit('**Kalma muna**\nSandali ');
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat-stop')));
    await tester.pump();
    expect(find.text('Itinigil.'), findsOneWidget);
    expect(find.text('Kalma muna'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('chat-input')), 'Isa pa');
    await tester.pump();
    final send = tester.widget<IconButton>(find.byKey(const Key('chat-send')));
    expect(send.onPressed, isNotNull);
  });

  testWidgets('plain text answer falls back to plain text', (tester) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Hello');
    ai.emit('Walang sections dito, simpleng sagot lang.');
    await ai.finish();
    await tester.pumpAndSettle();

    expect(
      find.text('Walang sections dito, simpleng sagot lang.'),
      findsOneWidget,
    );
    expect(find.text('Kalma muna'), findsNothing);
    expect(find.text(answerDisclaimer), findsOneWidget);
  });

  testWidgets('quick chips: "…" fills the box, full question sends', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);

    await tester.tap(find.byKey(const Key('quick-0')));
    await tester.pump();
    expect(inputText(tester), 'Magkano multa sa ');
    expect(ai.asked, isEmpty);

    await tester.ensureVisible(find.byKey(const Key('quick-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-2')));
    await tester.pump();
    expect(ai.asked, ['Nabangga ako, sino may mali?']);
  });

  testWidgets('mic: tap, tap again → transcript fills the box', (tester) async {
    await pumpChat(tester, ai: ControlledAi());
    await tester.tap(find.byKey(const Key('chat-mic')));
    await tester.pump();
    expect(find.text('Nakikinig… (pindutin ulit)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-mic')));
    await tester.pumpAndSettle();
    expect(inputText(tester), 'Pwede ba mag-U-turn dito?');
  });

  testWidgets('Dalawang panig: A → B → Suriin → result → Bagong kaso', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);

    await tester.tap(find.text('Dalawang panig'));
    await tester.pumpAndSettle();
    expect(find.text('Ano ang nangyari sa panig mo?'), findsOneWidget);
    expect(find.text('Magkano multa sa…'), findsNothing);

    await tester.enterText(find.byKey(const Key('chat-input')), 'Nauna ako');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-action'))); // Susunod
    await tester.pumpAndSettle();
    expect(find.text('Ano ang sabi ng kabilang driver?'), findsOneWidget);
    expect(find.text('Nauna ako'), findsOneWidget);
    expect(inputText(tester), isEmpty);

    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Siya ang nauna',
    );
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Suriin'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-action')));
    await tester.pump();
    expect(ai.twoSides, [('Nauna ako', 'Siya ang nauna')]);
    expect(find.text('Panig mo'), findsOneWidget);
    expect(find.text('Kabilang driver'), findsOneWidget);
    expect(find.byKey(const Key('chat-stop')), findsOneWidget);
    expect(find.byKey(const Key('new-case')), findsNothing);

    ai.emit(_answer);
    await ai.finish();
    await tester.pumpAndSettle();
    expect(find.text('Ano ang sinasabi ng batas'), findsOneWidget);
    expect(find.text(answerDisclaimer), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-case')));
    await tester.pumpAndSettle();
    expect(find.text('Ano ang nangyari sa panig mo?'), findsOneWidget);
    expect(find.text('Nauna ako'), findsNothing);
  });

  testWidgets('auto-scrolls to the bottom while streaming', (tester) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai, logicalSize: const Size(360, 640));
    await typeAndSend(tester, 'Mahabang sagot');
    for (var i = 0; i < 60; i++) {
      ai.emit('Linya $i ng mahabang sagot.\n');
      await tester.pump();
    }
    await tester.pump();
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, position.maxScrollExtent);
    expect(tester.takeException(), isNull);
    await ai.finish();
  });

  testWidgets('history clears when leaving the screen', (tester) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Unang tanong');
    ai.emit('Sagot.');
    await ai.finish();
    await tester.pumpAndSettle();
    expect(find.text('Unang tanong'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('EMERGENCY'), findsOneWidget);

    GoRouter.of(tester.element(find.text('EMERGENCY'))).push('/chat');
    await tester.pumpAndSettle();
    expect(find.text('Unang tanong'), findsNothing);
    expect(find.text('Magkano multa sa…'), findsOneWidget);
  });

  testWidgets('real fake AI renders all 4 sections + citation', (tester) async {
    await pumpChat(tester, ai: FakeAiAssistant(tokenDelay: Duration.zero));
    await typeAndSend(tester, 'Nabangga ako, sino may mali?');
    await tester.pumpAndSettle();
    for (final kind in AnswerSectionKind.values) {
      expect(find.text(kind.label), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('citation-RA 4136 Sec. 55')),
      findsOneWidget,
    );
  });

  testWidgets('small phone + 1.5x text: answer and input fit', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpChat(
      tester,
      ai: FakeAiAssistant(tokenDelay: Duration.zero),
      logicalSize: const Size(360, 640),
    );
    expect(tester.takeException(), isNull);
    await typeAndSend(tester, 'Nabangga ako, sino may mali?');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Dalawang panig'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('parseAnswer', () {
    test('accepts short headers and markdown variants', () {
      final p = parseAnswer(
        'Intro.\n**Kalma muna.** Relax lang.\n## Batas\nRA 4136 Sec. 35\n'
        'Pagsusuri: Ok.\n**Gagawin:**\n1. Tumabi.',
      );
      expect(p.intro, 'Intro.');
      expect(p.sections.map((s) => s.kind), AnswerSectionKind.values);
      expect(p.sections[0].body, 'Relax lang.');
      expect(p.sections[1].body, 'RA 4136 Sec. 35');
      expect(p.sections[2].body, 'Ok.');
      expect(p.sections[3].body, '1. Tumabi.');
    });

    test('body lines starting with a header word are not headers', () {
      final p = parseAnswer('Batas ng trapiko ang sinusunod natin.');
      expect(p.hasSections, isFalse);
      expect(p.intro, 'Batas ng trapiko ang sinusunod natin.');
    });

    test('citation pattern', () {
      String? match(String s) => citationPattern.firstMatch(s)?.group(0);
      expect(match('ayon sa RA 4136 Sec. 38.'), 'RA 4136 Sec. 38');
      expect(match('R.A. No. 10913'), 'R.A. No. 10913');
      expect(match('LTO JAO 2014-01'), 'LTO JAO 2014-01');
      expect(match('MMDA Reg. 96-005'), 'MMDA Reg. 96-005');
      expect(match('walang batas dito'), isNull);
    });
  });
}
