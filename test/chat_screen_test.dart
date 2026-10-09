import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biyahebuddy_ph/app.dart';
import 'package:biyahebuddy_ph/core/config/features.dart';
import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/core/di/providers.dart';
import 'package:biyahebuddy_ph/core/fakes/fakes.dart';
import 'package:biyahebuddy_ph/core/router/app_router.dart';
import 'package:biyahebuddy_ph/features/chat/controllers/answer_format.dart';
import 'package:biyahebuddy_ph/features/chat/controllers/flag_flow.dart';
import 'package:biyahebuddy_ph/features/chat/controllers/topics.dart';
import 'package:biyahebuddy_ph/features/chat/controllers/answer_reveal.dart';
import 'package:biyahebuddy_ph/features/chat/widgets/buddy_answer.dart';
import 'package:biyahebuddy_ph/features/chat/widgets/law_sheet.dart';
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
  router.go(location); // Buddy is a tab
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

    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    expect(find.byKey(const Key('offline-badge')), findsOneWidget);
    expect(find.text('Ano ang tanong mo?'), findsOneWidget);
    expect(find.byKey(const Key('topic-markings')), findsOneWidget);
    expect(
      find.byKey(const Key('topic-coding'), skipOffstage: false),
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
    expect(find.text('Ano ang tanong mo?'), findsNothing);
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
    final buddyLabel = find.descendant(
      of: find.byType(BuddyAnswer),
      matching: find.text('Buddy'),
    );
    expect(tester.getTopLeft(buddyLabel).dx, lessThan(412 / 4));
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

  group('topic menu', () {
    Future<void> tapAndSettle(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)).last);
      await tester.pumpAndSettle();
    }

    testWidgets('category → questions → answer → more questions', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await tapAndSettle(tester, 'topic-markings');
      expect(ai.asked, isEmpty);
      expect(find.text('Pumili ng tanong:'), findsOneWidget);
      expect(
        find.text('Pwede ba mag-overtake sa double solid yellow line?'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('topics-back')), findsOneWidget);

      await tapAndSettle(tester, 'topic-q-0');
      // Sent exactly as the curated FAQ question.
      expect(ai.asked, ['Pwede ba mag-overtake sa double solid yellow line?']);
      ai.emit(_answer);
      await ai.finish();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('section-batas')), findsOneWidget);
      expect(
        find.text('Iba pang tanong sa Road Markings & Overtaking'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('topic-more-0')), findsOneWidget);
      expect(find.byKey(const Key('topics-all')), findsOneWidget);

      // A follow-up chip asks the next question of the same topic.
      await tapAndSettle(tester, 'topic-more-0');
      expect(
        ai.asked.last,
        'Pwede ba mag-overtake sa isang solid na dilaw na linya?',
      );
      await ai.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('back navigation: questions → all topics → another topic', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await tapAndSettle(tester, 'topic-cellphone');
      await tapAndSettle(tester, 'topics-back');
      expect(find.text('Pumili ng topic:'), findsOneWidget);
      // The full grid is shown again in the chat.
      expect(find.byKey(const Key('topic-coding')), findsOneWidget);
      await tapAndSettle(tester, 'topic-coding');
      expect(find.text('Anong oras ang number coding?'), findsOneWidget);
      expect(ai.asked, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Traffic Stops → "Na-flag ako…" starts the guided flow', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await tapAndSettle(tester, 'topic-traffic-stops');
      await tapAndSettle(tester, 'topic-q-0');
      expect(ai.asked, isEmpty);
      expect(find.textContaining(flagQuestion), findsOneWidget);
    });

    test('12 topics; every question is answerable from faq.json', () {
      final faq = {
        for (final e
            in (jsonDecode(File('assets/data/faq.json').readAsStringSync())
                as List<dynamic>))
          (e as Map<String, dynamic>)['question'] as String,
      };
      expect(buddyTopics, hasLength(12));
      for (final t in buddyTopics) {
        expect(t.questions.length, inInclusiveRange(2, 5), reason: t.id);
        for (final q in t.questions) {
          if (q == flagFlowQuestion) {
            expect(isFlaggedWithoutViolation(q), isTrue);
          } else {
            expect(faq, contains(q), reason: '${t.id}: $q');
          }
        }
      }
    });
  });

  testWidgets('no mic anywhere in chat when voice input is disabled', (
    tester,
  ) async {
    await pumpChat(tester, ai: ControlledAi());
    expect(find.byKey(const Key('chat-mic')), findsNothing);
    if (kTwoSidesEnabled) {
      await tester.tap(find.text('Dalawang panig'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-mic')), findsNothing);
    }
  }, skip: kVoiceInputEnabled);

  testWidgets('no Tanong | Dalawang panig toggle when it is disabled', (
    tester,
  ) async {
    await pumpChat(tester, ai: ControlledAi());
    expect(find.byKey(const Key('chat-mode')), findsNothing);
    expect(find.text('Dalawang panig'), findsNothing);
    // Header still there; the chat starts right under it (no empty gap).
    expect(find.widgetWithText(AppBar, 'Buddy'), findsOneWidget);
    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    final title = tester.getRect(find.text('Ano ang tanong mo?'));
    expect(title.top - appBarBottom, lessThan(40));
  }, skip: kTwoSidesEnabled);

  group('natural reply (animations on)', () {
    Future<void> motionOn(WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
    }

    String shownText(WidgetTester tester) => tester
        .widgetList<RichText>(
          find.descendant(
            of: find.byType(BuddyAnswer),
            matching: find.byType(RichText),
          ),
        )
        .map((r) => r.text.toPlainText())
        .join(' ');

    testWidgets('typing dots first, at least 600 ms, even if ready at once', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await motionOn(tester); // after pumpChat: Home's SOS glow never settles
      await typeAndSend(tester, 'Tanong');
      ai.emit(_answer);
      await ai.finish();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('typing-dots')), findsOneWidget);
      expect(find.byKey(const Key('section-kalma')), findsNothing);
      expect(find.byKey(const Key('chat-stop')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('typing-dots')), findsNothing);
      // Let it finish so no ticker is left running.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('progressive reveal: sections appear one at a time', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await motionOn(tester); // after pumpChat: Home's SOS glow never settles
      await typeAndSend(tester, 'Tanong');
      ai.emit(_answer);
      await ai.finish();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      // A few words in: Kalma is there, later sections not yet.
      expect(find.byKey(const Key('section-kalma')), findsOneWidget);
      expect(find.byKey(const Key('section-gagawin')), findsNothing);
      expect(find.text(answerDisclaimer), findsNothing);
      expect(shownText(tester), isNot(contains('Kunan ng litrato')));
      expect(find.byKey(const Key('chat-stop')), findsOneWidget);

      // ~38 words/s: the whole answer (~30 units) lands within ~1.5 s.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (final kind in AnswerSectionKind.values) {
        expect(find.byKey(Key('section-${kind.name}')), findsOneWidget);
      }
      expect(shownText(tester), contains('Kunan ng litrato'));
      expect(find.text(answerDisclaimer), findsOneWidget);
      expect(find.byKey(const Key('chat-stop')), findsNothing);
      expect(find.byKey(const Key('chat-send')), findsOneWidget);
    });

    testWidgets('tap the answer while typing → full answer at once', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await motionOn(tester); // after pumpChat: Home's SOS glow never settles
      await typeAndSend(tester, 'Tanong');
      ai.emit(_answer);
      await ai.finish();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('section-gagawin')), findsNothing);

      await tester.tap(find.byKey(const Key('buddy-answer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 300));
      for (final kind in AnswerSectionKind.values) {
        expect(find.byKey(Key('section-${kind.name}')), findsOneWidget);
      }
      expect(find.text(answerDisclaimer), findsOneWidget);
      expect(find.byKey(const Key('chat-send')), findsOneWidget);
    });

    testWidgets('Stop freezes the reveal even after the stream ended', (
      tester,
    ) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await motionOn(tester); // after pumpChat: Home's SOS glow never settles
      await typeAndSend(tester, 'Tanong');
      ai.emit(_answer);
      await ai.finish();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.tap(find.byKey(const Key('chat-stop')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Itinigil.'), findsOneWidget);
      expect(find.byKey(const Key('section-gagawin')), findsNothing);
      expect(find.byKey(const Key('chat-send')), findsOneWidget);
    });
  });

  testWidgets('reduce motion: no typing delay, text shows as it arrives', (
    tester,
  ) async {
    // flutter_test_config turns reduce motion on for every test.
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Tanong');
    ai.emit(_answer);
    await tester.pump();
    for (final kind in AnswerSectionKind.values) {
      expect(find.byKey(Key('section-${kind.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('typing-dots')), findsNothing);
    await ai.finish();
    await tester.pump();
    expect(find.text(answerDisclaimer), findsOneWidget);
  });

  testWidgets('tap a law pill → bottom sheet with the full section text', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Sino ang may right of way?');
    ai.emit(_answer);
    await ai.finish();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('citation-RA 4136 Sec. 42')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('law-sheet')), findsOneWidget);
    expect(find.textContaining('Right of way'), findsOneWidget);
    final text = tester
        .widget<SelectableText>(find.byKey(const Key('law-sheet-text')))
        .data!;
    expect(text.length, greaterThan(200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one answer card: law = pill + 2-line excerpt + read link; '
      'steps numbered', (tester) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Sino ang may right of way?');
    ai.emit(
      '**Kalma muna**\nOk lang.\n\n'
      '**Ano ang sinasabi ng batas**\nMahabang paliwanag (RA 4136 Sec. 42).\n\n'
      '**Pagsusuri**\nIkaw ang nauna.\n\n'
      '**Ano ang gagawin**\n1. Kunan ng litrato.\n2. Tumawag sa 911.',
    );
    await ai.finish();
    await tester.pumpAndSettle();

    // Batas: the law text (from laws.json), not the long AI paragraph.
    final excerpt = tester.widget<Text>(find.byKey(const Key('law-excerpt')));
    expect(excerpt.maxLines, 2);
    expect(find.textContaining('Mahabang paliwanag'), findsNothing);
    expect(
      find.byKey(const ValueKey('citation-RA 4136 Sec. 42')),
      findsOneWidget,
    );
    // Gagawin: numbered rows.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Kunan ng litrato'), findsOneWidget);
    // Header: just a small Offline dot.
    expect(find.byKey(const Key('offline-badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('read-law')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('law-sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('guided na-flag flow', () {
    Future<ControlledAi> startFlow(WidgetTester tester, String q) async {
      final ai = ControlledAi();
      await pumpChat(tester, ai: ai);
      await typeAndSend(tester, q);
      await tester.pumpAndSettle();
      return ai;
    }

    testWidgets('flagged without a violation → follow-up question + chips', (
      tester,
    ) async {
      final ai = await startFlow(
        tester,
        'Na-flag ako ng MMDA, ano ang dapat gawin ko?',
      );
      expect(ai.asked, isEmpty); // code-driven, no LLM
      expect(find.textContaining(flagQuestion), findsOneWidget);
      expect(find.byKey(const Key('flag-chip-0')), findsOneWidget);
      expect(find.text('Disregarding traffic signs'), findsOneWidget); // MMDA
      expect(find.text('Driving without a valid license'), findsNothing); // LTO
      expect(tester.takeException(), isNull);
    });

    testWidgets('chip tap → fine card with ₱, steps and IPAKITA', (
      tester,
    ) async {
      final ai = await startFlow(tester, 'Pinara ako ng MMDA');
      await tester.tap(find.text('Disregarding traffic signs'));
      await tester.pumpAndSettle();
      expect(ai.asked, isEmpty);
      expect(find.byKey(const Key('flag-fine-card')), findsOneWidget);
      expect(find.text('₱1,000'), findsOneWidget);
      expect(find.textContaining('official ticket'), findsOneWidget);
      expect(find.textContaining('Huwag magbayad on the spot'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('flag-ipakita')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flag-ipakita')));
      await tester.pumpAndSettle();
      expect(find.text('Magandang araw po.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typed violation is matched with the Na-flag fine search', (
      tester,
    ) async {
      final ai = await startFlow(tester, 'Hinuli ako ng LTO enforcer');
      expect(find.text('Driving without a valid license'), findsOneWidget);
      await typeAndSend(tester, 'cellphone');
      await tester.pumpAndSettle();
      expect(ai.asked, isEmpty);
      expect(find.byKey(const Key('flag-fine-card')), findsOneWidget);
      expect(find.text('Using mobile phone while driving'), findsOneWidget);
      expect(find.text('₱5,000'), findsOneWidget);
    });

    testWidgets('no match → message, chips again, open Na-flag ako', (
      tester,
    ) async {
      await startFlow(tester, 'Na-flag ako');
      await typeAndSend(tester, 'kalabaw sa kalsada');
      await tester.pumpAndSettle();
      expect(find.textContaining(flagNoMatch), findsOneWidget);
      expect(find.byKey(const Key('flag-fine-card')), findsNothing);
      expect(find.byKey(const Key('flag-chip-0')), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('flag-open-violation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flag-open-violation')));
      await tester.pumpAndSettle();
      expect(find.text("Sino ang nag-flag sa'yo?"), findsOneWidget);
    });

    test('intent + agency detection', () {
      expect(
        isFlaggedWithoutViolation('Na-flag ako ng MMDA, ano gagawin?'),
        isTrue,
      );
      expect(isFlaggedWithoutViolation('Pinara ako ng enforcer'), isTrue);
      expect(
        isFlaggedWithoutViolation('Na-flag ako kasi walang helmet'),
        isFalse,
      );
      expect(isFlaggedWithoutViolation('Magkano multa sa helmet?'), isFalse);
      expect(detectAgency('hinuli ako ng LTO'), Agency.lto);
      expect(detectAgency('enforcer ng QC'), Agency.city);
      expect(detectAgency('na-flag ako'), Agency.mmda);
    });
  });

  test('lawIdFor maps citations to laws.json ids', () {
    expect(lawIdFor('RA 4136 Sec. 42'), 'ra4136-s42');
    expect(lawIdFor('R.A. No. 10913, Section 4'), 'ra10913-s4');
    expect(lawIdFor('MMDA Reg. 96-005'), isNull);
    expect(lawIdFor('RA 4136'), isNull);
  });

  test('revealUnits keeps headers and citations whole', () {
    final u = revealUnits(_answer);
    expect(u.join(), _answer);
    expect(u, contains('**Ano ang sinasabi ng batas**\n'));
    expect(u.any((w) => w.startsWith('RA 4136 Sec. 42')), isTrue);
    // A header still arriving is held back.
    expect(revealUnits('Hi.\n**Ano ang', streaming: true).join(), 'Hi.\n');
  });

  testWidgets('mic: tap, tap again → transcript fills the box', (tester) async {
    await pumpChat(tester, ai: ControlledAi());
    await tester.tap(find.byKey(const Key('chat-mic')));
    await tester.pump();
    expect(find.text('Nakikinig… (pindutin ulit)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-mic')));
    await tester.pumpAndSettle();
    expect(inputText(tester), 'Pwede ba mag-U-turn dito?');
  }, skip: !kVoiceInputEnabled);

  testWidgets('Dalawang panig: A → B → Suriin → result → Bagong kaso', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);

    await tester.tap(find.text('Dalawang panig'));
    await tester.pumpAndSettle();
    expect(find.text('Ano ang nangyari sa panig mo?'), findsOneWidget);
    expect(find.text('Ano ang tanong mo?'), findsNothing);

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

    // Cupertino action sheet: cancel keeps the result, confirm resets.
    await tester.tap(find.byKey(const Key('new-case')));
    await tester.pumpAndSettle();
    expect(find.text('Bagong kaso?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sheet-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Ano ang sinasabi ng batas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-case')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sheet-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Ano ang nangyari sa panig mo?'), findsOneWidget);
    expect(find.text('Nauna ako'), findsNothing);
  }, skip: !kTwoSidesEnabled);

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

  testWidgets('history stays while switching tabs', (tester) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await typeAndSend(tester, 'Unang tanong');
    ai.emit('Sagot.');
    await ai.finish();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();
    expect(find.text('SOS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-chat')));
    await tester.pumpAndSettle();
    expect(find.text('Unang tanong'), findsOneWidget);
  });

  testWidgets('a new ?q= fills the box even when the tab already exists', (
    tester,
  ) async {
    final ai = ControlledAi();
    await pumpChat(tester, ai: ai);
    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.text('SOS')),
    ).go('/chat?q=${Uri.encodeQueryComponent('Na-flag ako ng MMDA')}');
    await tester.pumpAndSettle();
    expect(inputText(tester), 'Na-flag ako ng MMDA');
    expect(ai.asked, isEmpty);
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

  for (final scale in [1.5, 2.0]) {
    testWidgets('small phone + ${scale}x text: answer and input fit', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
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
      if (kTwoSidesEnabled) {
        await tester.tap(find.text('Dalawang panig'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

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
