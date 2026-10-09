import 'dart:async';

import 'package:biyahebuddy_ph/data/ai/local_ai_assistant.dart';
import 'package:biyahebuddy_ph/data/ai/local_llm.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/rag/law_retriever.dart';
import 'package:flutter_test/flutter_test.dart';

const _laws = '''
[
  {"id": "ra10054-s7", "source": "RA 10054 (Motorcycle Helmet Act of 2009)",
   "section": "Sec. 7", "title": "Penalties",
   "text": "Any person who violates this Act shall be fined: first offense 1,500 pesos.",
   "tags": ["helmet", "motor", "multa"]},
  {"id": "ra4136-s44", "source": "RA 4136 (Land Transportation and Traffic Code)",
   "section": "Sec. 44", "title": "Signals on starting, stopping or turning",
   "text": "The driver of any vehicle, before turning, shall give a signal plainly visible.",
   "tags": ["signal", "kumanan", "kumaliwa", "liko"]},
  {"id": "ra4136-s41", "source": "RA 4136 (Land Transportation and Traffic Code)",
   "section": "Sec. 41", "title": "Restrictions on overtaking and passing",
   "text": "The driver of a vehicle shall not overtake another vehicle on a curve.",
   "tags": ["overtake", "nag-overtake", "double yellow"]}
]
''';

const _fines = '''
[{"violation": "No helmet", "agency": "lto", "amount": 1500,
  "legal_basis": "RA 10054 Sec. 7", "aliases": ["walang helmet", "helmet"]}]
''';

/// Scripted LLM: replies with [reply] in small pieces.
class FakeGenerator implements TextGenerator {
  FakeGenerator(this.reply, {this.fail = false});

  final String reply;
  final bool fail;
  String? lastUser;
  bool cancelled = false;

  @override
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 0,
  }) async* {
    lastUser = user;
    try {
      for (var i = 0; i < reply.length; i += 4) {
        await Future<void>.delayed(Duration.zero);
        yield reply.substring(i, (i + 4).clamp(0, reply.length));
      }
      if (fail) throw StateError('native crash');
    } finally {
      cancelled = true;
    }
  }
}

const _headers = [
  '**Kalma muna**',
  '**Ano ang sinasabi ng batas**',
  '**Pagsusuri**',
  '**Ano ang gagawin**',
];

/// Every header on its own line, once, in order.
void expectFormat(String answer) {
  final lines = answer.split('\n');
  final found = lines.where(_headers.contains).toList();
  expect(found, _headers, reason: answer);
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.open(':memory:', lawsJson: _laws, finesJson: _fines));
  tearDown(() => db.close());

  LocalAiAssistant buddy(TextGenerator llm, {bool ready = true}) =>
      LocalAiAssistant(
        retriever: LawRetriever(db),
        llm: llm,
        isModelReady: () => ready,
      );

  const modelReply =
      'Pagsusuri:\nAyon sa RA 10054 Sec. 7, may multa ang walang helmet.\n'
      'Gagawin:\n1. Magsuot ng helmet.\n2. Bayaran ang multa sa LTO.';

  test('ask: 4 sections in order, real citation and fine from data', () async {
    final llm = FakeGenerator(modelReply);
    final answer = await buddy(llm).ask('Magkano multa pag walang helmet?').join();
    expectFormat(answer);
    expect(answer, contains('RA 10054 Sec. 7 — Penalties'));
    expect(answer, contains('Multa (LTO): ₱1,500'));
    expect(answer, contains('Ayon sa RA 10054 Sec. 7, may multa'));
    expect(answer, isNot(contains('Model step')));
    expect(answer, contains('Itala ang pangalan at ID ng enforcer')); // fine steps
    // The LLM got the retrieved law as context.
    expect(llm.lastUser, contains('[RA 10054 Sec. 7 — Penalties]'));
  });

  test('two sides: neutral steps, 911 in the opener, signal law retrieved', () async {
    final answer = await buddy(FakeGenerator('Pagsusuri:\nParehong panig.'))
        .analyzeTwoSides(
          'Bigla siyang kumanan nang walang signal light, umabante ako.',
          'Naka-signal ako, mabilis siya.',
        )
        .join();
    expectFormat(answer);
    expect(answer, contains('RA 4136 Sec. 44'));
    expect(answer, contains('tumawag agad sa 911'));
    expect(answer, contains('Kunan ng litrato')); // two-sides steps
    expect(answer, contains('Parehong panig.'));
  });

  test('two sides: sentences that assign fault are removed', () async {
    final answer = await buddy(
      FakeGenerator(
        'Kung totoo ang kuwento ni Driver A, may kasalanan si Driver B. '
        'Tinitingnan ng RA 4136 Sec. 44 kung nag-signal bago lumiko.\n'
        'Nagkamali si Driver A.',
      ),
    ).analyzeTwoSides('Kumanan siya bigla.', 'Naka-signal ako.').join();
    expectFormat(answer);
    expect(answer, isNot(contains('kasalanan')));
    expect(answer, isNot(contains('Nagkamali')));
    expect(answer, contains('Tinitingnan ng RA 4136 Sec. 44 kung nag-signal'));
  });

  test('two sides: only fault sentences → neutral fallback', () async {
    final answer = await buddy(FakeGenerator('Si Driver A ang may sala.'))
        .analyzeTwoSides('Kumanan siya bigla.', 'Naka-signal ako.')
        .join();
    expect(answer, isNot(contains('Si Driver A ang may sala')));
    expect(answer, contains('Ang pulis o korte ang magpapasya'));
  });

  test('no matching law: says so plainly and never calls the LLM', () async {
    final llm = FakeGenerator('should not be used');
    final answer = await buddy(llm).ask('Ano ang paboritong kulay mo?').join();
    expectFormat(answer);
    expect(answer, contains('Walang malinaw na batas para dito'));
    expect(llm.lastUser, isNull);
  });

  test('model not downloaded: full answer from retrieval only', () async {
    final llm = FakeGenerator('unused');
    final answer = await buddy(llm, ready: false).ask('walang helmet').join();
    expectFormat(answer);
    expect(answer, contains('i-download muna ang AI model'));
    expect(llm.lastUser, isNull);
  });

  test('model error mid-answer: stream still completes with all sections', () async {
    final answer = await buddy(FakeGenerator('Pagsusuri: Ayon sa', fail: true))
        .ask('helmet')
        .join();
    expectFormat(answer);
    expect(answer, contains('Hindi natapos'));
  });

  test('injury words add the 911 step', () async {
    final answer = await buddy(FakeGenerator('Pagsusuri: x'))
        .ask('Nag-overtake siya, may nasaktan')
        .join();
    expect(answer, contains('1. Kung may nasaktan, tumawag agad sa 911.'));
  });

  test('cancelling the answer (Stop button) cancels generation', () async {
    final llm = FakeGenerator('Pagsusuri:\n${'mahabang sagot ' * 50}');
    final got = Completer<void>();
    late StreamSubscription<String> sub;
    sub = buddy(llm).ask('helmet').listen((chunk) {
      if (chunk.contains('maha') && !got.isCompleted) got.complete();
    });
    await got.future;
    await sub.cancel();
    expect(llm.cancelled, isTrue);
  });
}
