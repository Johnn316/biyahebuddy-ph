import '../../core/contracts/contracts.dart';
import '../rag/hybrid_retriever.dart';
import '../rag/law_retriever.dart';
import '../rag/intent.dart';
import 'answer_parts.dart';
import 'citation_guard.dart';
import 'local_llm.dart';
import 'section_filter.dart';

export '../rag/hybrid_retriever.dart' show Retrieved;

/// On-device Buddy: local RAG + local LLM (llama.cpp).
///
/// Retrieval is hybrid (FTS5 keywords + multilingual embeddings, see
/// [HybridRetriever]) when the embedding model is downloaded, else FTS5 only.
///
/// Code writes "Kalma muna", "Ano ang sinasabi ng batas" (verbatim retrieved
/// law with real citations) and "Ano ang gagawin" (safe, situation-specific
/// steps). The LLM writes only the short "Pagsusuri". Without a model (not
/// downloaded, load error) the answer still has all four sections.
class LocalAiAssistant implements AiAssistant {
  LocalAiAssistant({
    required this.retriever,
    required this.llm,
    required this.isModelReady,
    this.hybrid,
    bool Function()? isHybridReady,
  }) : isHybridReady = isHybridReady ?? (() => hybrid != null);

  final LawRetriever retriever;
  final TextGenerator llm;
  final bool Function() isModelReady;

  /// Semantic + keyword retrieval; used while [isHybridReady] is true.
  final HybridRetriever? hybrid;
  final bool Function() isHybridReady;

  /// What [ask] cites for [question]. Public so tools/eval measures exactly
  /// the retrieval the app uses.
  Future<Retrieved> retrieve(String question) async {
    final aboutFine = AnswerParts.asksAboutFine(question);
    final h = hybrid;
    if (h != null && isHybridReady()) {
      return h.retrieve(question, aboutFine: aboutFine);
    }
    return (
      laws: retriever.laws(question, aboutFine: aboutFine),
      fines: aboutFine ? retriever.fines(question) : const <Fine>[],
    );
  }

  /// What [analyzeTwoSides] cites.
  Future<Retrieved> retrieveTwoSides(String driverA, String driverB) async {
    final h = hybrid;
    if (h != null && isHybridReady()) {
      return h.retrieveTwoSides(driverA, driverB);
    }
    return (laws: retriever.laws('$driverA\n$driverB'), fines: const <Fine>[]);
  }

  @override
  Stream<String> ask(String question) async* {
    final injury = AnswerParts.mentionsInjury(question);
    final aboutFine = AnswerParts.asksAboutFine(question);
    final (:laws, :fines) = await retrieve(question);
    yield* _answer(
      kalma: AnswerParts.kalma(injury: injury),
      laws: laws,
      fines: fines,
      system: AnswerParts.askSystem,
      user: AnswerParts.askUser(AnswerParts.llmContext(laws, fines), question),
      steps: AnswerParts.gagawin(
        injury: injury,
        aboutFine: aboutFine,
        accident: AnswerParts.mentionsAccident(question),
      ),
    );
  }

  @override
  Stream<String> analyzeTwoSides(String driverA, String driverB) async* {
    final both = '$driverA\n$driverB';
    final (:laws, fines: _) = await retrieveTwoSides(driverA, driverB);
    yield* _answer(
      kalma: AnswerParts.kalma(
        injury: AnswerParts.mentionsInjury(both),
        twoSides: true,
      ),
      laws: laws,
      fines: const [],
      system: AnswerParts.twoSidesSystem,
      user: AnswerParts.twoSidesUser(
        AnswerParts.llmContext(laws, const []),
        driverA,
        driverB,
      ),
      steps: AnswerParts.gagawin(twoSides: true),
      frame: AnswerParts.twoSidesFrame,
      neutral: true,
    );
  }

  Stream<String> _answer({
    required String kalma,
    required List<LawChunk> laws,
    required List<Fine> fines,
    required String system,
    required String user,
    required String steps,
    String frame = '',
    bool neutral = false,
  }) async* {
    yield kalma;
    yield AnswerParts.batas(laws, fines);
    yield '${AnswerParts.pagsusuriHeader}\n';

    if (laws.isEmpty && fines.isEmpty) {
      yield AnswerParts.noMatchAnalysis;
    } else if (!isModelReady()) {
      yield AnswerParts.modelMissingAnalysis;
    } else {
      if (frame.isNotEmpty) yield frame;
      final filter = SectionFilter();
      // Only sections actually shown above (laws + fines' own legal basis).
      final guard = CitationGuard({
        for (final l in laws) l.id,
        for (final f in fines) ...lawIdsInLegalBasis(f.legalBasis),
      });
      // Neutral mode collects the analysis first so fault-assigning
      // sentences can be removed before anything is shown.
      final held = StringBuffer();
      var failed = false;
      try {
        // Leaving the loop cancels the subscription, which stops generation.
        await for (final chunk in llm.generate(system: system, user: user)) {
          final text = filter.add(chunk);
          if (neutral) {
            held.write(text);
          } else {
            final safe = guard.add(text);
            if (safe.isNotEmpty) yield safe;
          }
          if (filter.done) break;
        }
      } on Object {
        failed = true;
      }
      if (neutral) {
        held.write(filter.close(fallback: ''));
        final clean = AnswerParts.dropFaultSentences(guard.clean('$held'));
        yield clean.isEmpty ? AnswerParts.neutralFallback : clean;
      } else {
        yield guard.add(
              filter.close(fallback: failed ? '' : AnswerParts.emptyAnalysis),
            ) +
            guard.close();
      }
      if (failed) yield AnswerParts.modelFailedNote;
      yield '\n';
    }
    yield steps;
  }
}
