import 'dart:convert';
import 'dart:io';

import 'package:biyahebuddy_ph/core/contracts/contracts.dart';
import 'package:biyahebuddy_ph/data/ai/local_ai_assistant.dart';
import 'package:biyahebuddy_ph/data/ai/local_llm.dart';
import 'package:biyahebuddy_ph/data/local/app_database.dart';
import 'package:biyahebuddy_ph/data/local/fts_query.dart';
import 'package:biyahebuddy_ph/data/rag/hybrid_retriever.dart';
import 'package:biyahebuddy_ph/data/rag/intent.dart';
import 'package:biyahebuddy_ph/data/rag/law_retriever.dart';
import 'package:biyahebuddy_ph/data/rag/text_embedder.dart';
import 'package:biyahebuddy_ph/data/rag/vector_index.dart';
import 'package:flutter_test/flutter_test.dart';

const _laws = '''
[
  {"id": "ra4136-s44", "source": "RA 4136 (Land Transportation and Traffic Code)",
   "section": "Sec. 44", "title": "Signals on starting, stopping or turning",
   "text": "Before turning, the driver shall give a signal plainly visible.",
   "tags": ["signal"]},
  {"id": "ra4136-s55", "source": "RA 4136 (Land Transportation and Traffic Code)",
   "section": "Sec. 55", "title": "Duty of driver in case of accident",
   "text": "No driver involved in an accident shall flee from the scene.",
   "tags": ["accident"]},
  {"id": "ra4136-s46", "source": "RA 4136 (Land Transportation and Traffic Code)",
   "section": "Sec. 46", "title": "Parking prohibited in specified places",
   "text": "No driver shall park a vehicle in front of a fire hydrant.",
   "tags": ["parking"]},
  {"id": "ra10054-s7", "source": "RA 10054 (Motorcycle Helmet Act of 2009)",
   "section": "Sec. 7", "title": "Penalties",
   "text": "Violators shall be fined 1,500 pesos for the first offense.",
   "tags": ["helmet", "multa"]}
]
''';

const _fines = '''
[
  {"violation": "No helmet — 1st offense", "agency": "lto", "amount": 1500,
   "legal_basis": "RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7",
   "aliases": ["walang helmet"]},
  {"violation": "No helmet — 2nd offense", "agency": "lto", "amount": 3000,
   "legal_basis": "RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7",
   "aliases": ["walang helmet"]},
  {"violation": "No helmet — 1st offense", "agency": "mmda", "amount": 1500,
   "legal_basis": "Metro Manila Traffic Code of 2023, Sec. 28 (RA 10054)",
   "aliases": ["walang helmet"]},
  {"violation": "Illegal parking", "agency": "mmda", "amount": 4000,
   "legal_basis": "Metro Manila Traffic Code of 2023, Sec. 10",
   "aliases": ["bawal pumarada"]}
]
''';

/// 4-dim "meaning" axes: turning, accident, parking, helmet.
const _axes = {
  'kumanan': [1.0, 0.0, 0.0, 0.0],
  'tumakas': [0.0, 1.0, 0.0, 0.0],
  'parada': [0.0, 0.0, 1.0, 0.0],
  'helmet': [0.0, 0.0, 0.0, 1.0],
};

/// Embeds by looking for an axis word in the text (deterministic).
class FakeEmbedder implements TextEmbedder {
  FakeEmbedder({this.fail = false});

  final bool fail;

  @override
  EmbeddingSpec get spec => EmbeddingSpec.embeddingGemma;

  @override
  Future<List<double>> embed(String text) async {
    if (fail) throw StateError('model missing');
    for (final e in _axes.entries) {
      if (text.toLowerCase().contains(e.key)) return e.value;
    }
    return const [0.5, 0.5, 0.5, 0.5];
  }
}

String _index({List<Map<String, dynamic>> faq = const []}) => jsonEncode({
  'model': EmbeddingSpec.embeddingGemma.id,
  'dims': 4,
  'source_hash': 0,
  'laws': {
    'ra4136-s44': VectorIndex.encode(_axes['kumanan']!),
    'ra4136-s55': VectorIndex.encode(_axes['tumakas']!),
    'ra4136-s46': VectorIndex.encode(_axes['parada']!),
    'ra10054-s7': VectorIndex.encode(_axes['helmet']!),
  },
  'fines': [
    for (final a in ['helmet', 'helmet', 'helmet', 'parada'])
      VectorIndex.encode(_axes[a]!),
  ],
  'fine_laws': [
    ['ra10054-s7'],
    ['ra10054-s7'],
    ['ra10054-s7'],
    ['ra4136-s46'],
  ],
  'faq': faq,
});

void main() {
  late AppDatabase db;
  late LawRetriever keyword;

  setUp(() {
    db = AppDatabase.open(':memory:', lawsJson: _laws, finesJson: _fines);
    keyword = LawRetriever(db);
  });
  tearDown(() => db.close());

  HybridRetriever hybrid({bool fail = false, String? index}) => HybridRetriever(
    keyword: keyword,
    index: VectorIndex.fromJson(index ?? _index()),
    embedder: FakeEmbedder(fail: fail),
  );

  group('Tagalog roots', () {
    test('strip prefixes, -um-/-in- infixes and reduplication', () {
      expect(tagalogRoots('nakaparada'), {'parada'});
      expect(tagalogRoots('pumarada'), {'parada'});
      expect(tagalogRoots('nagmamaneho'), {'maneho'});
      expect(tagalogRoots('kumanan'), {'kanan'});
      expect(tagalogRoots('nabangga'), {'bangga'});
      expect(tagalogRoots('helmet'), isEmpty);
    });

    test('FTS query OR-s a word with its root, also in AND mode', () {
      expect(ftsQuery('nakaparada'), '("nakaparada"* OR "parada"*)');
      expect(ftsQuery('walang helmet', allWords: true), '"helmet"*');
    });

    test('index side gets roots too, so affixed forms meet', () {
      expect(AppDatabase.withRoots('bawal pumarada'), contains('parada'));
      expect(keyword.fineRows('Nakaparada ako dito'), [4]);
    });
  });

  test('legal basis → law id only when it starts with an RA', () {
    expect(
      lawIdsInLegalBasis('RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7'),
      ['ra10054-s7'],
    );
    expect(
      lawIdsInLegalBasis(
        'Metro Manila Traffic Code of 2023, Sec. 28 (RA 10054)',
      ),
      isEmpty,
    );
  });

  test('intent routing', () {
    expect(classifyIntent('Magkano multa sa helmet?'), contains(Intent.fine));
    expect(classifyIntent('Nabangga ako'), contains(Intent.accident));
    expect(classifyIntent('Hinuli ako ng MMDA'), contains(Intent.enforcer));
    expect(classifyIntent('Sino ang mauuna?'), contains(Intent.rightOfWay));
    expect(classifyIntent('Kailangan ba ng plaka?'), {Intent.general});
  });

  group('HybridRetriever', () {
    test('semantic match finds a section keywords cannot', () async {
      // No shared keyword with "Signals on starting, stopping or turning".
      final r = await hybrid().retrieve(
        'Bigla siyang kumanan',
        aboutFine: false,
      );
      expect(r.laws.first.id, 'ra4136-s44');
    });

    test('accident anchor: Sec. 55 is always a candidate', () async {
      final r = await hybrid().retrieve(
        'Tumakas yung nakabangga sa akin',
        aboutFine: false,
      );
      expect(r.laws.map((l) => l.id), contains('ra4136-s55'));
    });

    test('a strong FAQ match pulls in its linked section', () async {
      final withFaq = _index(
        faq: [
          {
            'text': 'Ano ang gagawin pag nakabangga?',
            'sections': ['ra4136-s46'],
            'vec': VectorIndex.encode(const [0.5, 0.5, 0.5, 0.5]),
          },
        ],
      );
      final r = await hybrid(
        index: withFaq,
      ).retrieve('Something generic', aboutFine: false);
      expect(r.laws.map((l) => l.id), contains('ra4136-s46'));
    });

    test('a weak FAQ match does not', () async {
      final withFaq = _index(
        faq: [
          {
            'text': 'unrelated',
            'sections': ['ra4136-s46'],
            'vec': VectorIndex.encode(const [1.0, 0.0, 0.0, 0.0]),
          },
        ],
      );
      final r = await hybrid(
        index: withFaq,
      ).retrieve('tumakas', aboutFine: false);
      expect(r.laws.first.id, isNot('ra4136-s46'));
    });

    test(
      'fines: one row per violation type, agency the driver named',
      () async {
        final r = await hybrid().retrieve(
          'Magkano multa walang helmet sa MMDA?',
          aboutFine: true,
        );
        expect(r.fines.first.violation, startsWith('No helmet'));
        expect(r.fines.first.agency, Agency.mmda);
        // The three helmet rows count as one type.
        expect(
          r.fines.where((f) => f.violation.startsWith('No helmet')),
          hasLength(1),
        );
        // The fine's own legal basis brings in its law section.
        expect(r.laws.map((l) => l.id), contains('ra10054-s7'));
      },
    );

    test('embedder failure falls back to keyword retrieval', () async {
      final r = await hybrid(
        fail: true,
      ).retrieve('parking fire hydrant', aboutFine: false);
      expect(r.laws.first.id, 'ra4136-s46');
    });
  });

  group('LocalAiAssistant', () {
    test('uses hybrid only while the embedder is ready', () async {
      var ready = true;
      final assistant = LocalAiAssistant(
        retriever: keyword,
        llm: _SilentLlm(),
        isModelReady: () => false,
        hybrid: hybrid(),
        isHybridReady: () => ready,
      );
      const q = 'Tumakas siya';
      expect(
        (await assistant.retrieve(q)).laws.map((l) => l.id),
        contains('ra4136-s55'),
      );
      ready = false;
      // Keyword-only has nothing for "tumakas" in the English law text.
      expect((await assistant.retrieve(q)).laws, isEmpty);
    });
  });

  test('bundled embeddings.json matches the bundled data', () {
    final laws = File('assets/data/laws.json').readAsStringSync();
    final fines = File('assets/data/fines.json').readAsStringSync();
    final faqFile = File('assets/data/faq.json');
    final faq = faqFile.existsSync() ? faqFile.readAsStringSync() : '[]';
    final index = VectorIndex.fromJson(
      File('assets/data/embeddings.json').readAsStringSync(),
    );
    expect(
      index.sourceHash,
      VectorIndex.hashSources(laws, fines, faq),
      reason: 'Data changed: run dart run tools/build_embeddings.dart',
    );
    expect(EmbeddingSpec.byId(index.modelId), EmbeddingSpec.embeddingGemma);
    expect(index.laws.length, (jsonDecode(laws) as List).length);
    expect(index.fines.length, (jsonDecode(fines) as List).length);
  });
}

class _SilentLlm implements TextGenerator {
  @override
  Stream<String> generate({
    required String system,
    required String user,
    int maxTokens = 0,
  }) => const Stream.empty();
}
