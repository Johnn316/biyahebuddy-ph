import '../../core/contracts/contracts.dart';
import '../rag/law_retriever.dart';
import 'answer_parts.dart';
import 'local_llm.dart';
import 'section_filter.dart';

/// On-device Buddy: local RAG (FTS5) + local LLM (llama.cpp).
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
  });

  final LawRetriever retriever;
  final TextGenerator llm;
  final bool Function() isModelReady;

  @override
  Stream<String> ask(String question) {
    final injury = AnswerParts.mentionsInjury(question);
    final aboutFine = AnswerParts.asksAboutFine(question);
    final laws = retriever.laws(question, aboutFine: aboutFine);
    final fines = aboutFine ? retriever.fines(question) : const <Fine>[];
    return _answer(
      kalma: AnswerParts.kalma(injury: injury),
      laws: laws,
      fines: fines,
      system: AnswerParts.askSystem,
      user: AnswerParts.askUser(
        AnswerParts.llmContext(laws, fines),
        question,
      ),
      steps: AnswerParts.gagawin(
        injury: injury,
        aboutFine: aboutFine,
        accident: AnswerParts.mentionsAccident(question),
      ),
    );
  }

  @override
  Stream<String> analyzeTwoSides(String driverA, String driverB) {
    final both = '$driverA\n$driverB';
    final laws = retriever.laws(both);
    return _answer(
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
          } else if (text.isNotEmpty) {
            yield text;
          }
          if (filter.done) break;
        }
      } on Object {
        failed = true;
      }
      if (neutral) {
        held.write(filter.close(fallback: ''));
        final clean = AnswerParts.dropFaultSentences('$held');
        yield clean.isEmpty ? AnswerParts.neutralFallback : clean;
      } else {
        yield filter.close(fallback: failed ? '' : AnswerParts.emptyAnalysis);
      }
      if (failed) yield AnswerParts.modelFailedNote;
      yield '\n';
    }
    yield steps;
  }
}
