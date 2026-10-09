import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';
import 'flag_flow.dart';

export 'flag_flow.dart';

enum ChatRole { user, buddy }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.label,
    this.streaming = false,
    this.stopped = false,
    this.failed = false,
    this.flag,
    this.agency,
    this.fine,
    this.chips = const [],
  });

  final ChatRole role;
  final String text;

  /// Small caption above a user bubble, e.g. "Panig mo".
  final String? label;
  final bool streaming;
  final bool stopped;
  final bool failed;

  /// Guided na-flag flow: what this Buddy message shows under its text.
  final FlagStep? flag;
  final Agency? agency;

  /// The matched fine ([FlagStep.fine]).
  final Fine? fine;

  /// Tappable violations ([FlagStep.askViolation] / [FlagStep.noMatch]).
  final List<String> chips;

  ChatMessage copyWith({
    String? text,
    bool? streaming,
    bool? stopped,
    bool? failed,
    FlagStep? flag,
    Agency? agency,
    Fine? fine,
    List<String>? chips,
  }) => ChatMessage(
    role: role,
    text: text ?? this.text,
    label: label,
    streaming: streaming ?? this.streaming,
    stopped: stopped ?? this.stopped,
    failed: failed ?? this.failed,
    flag: flag ?? this.flag,
    agency: agency ?? this.agency,
    fine: fine ?? this.fine,
    chips: chips ?? this.chips,
  );
}

enum ChatMode { ask, twoSides }

enum TwoSidesStep { sideA, sideB, result }

class ChatState {
  const ChatState({
    this.mode = ChatMode.ask,
    this.askMessages = const [],
    this.twoSidesStep = TwoSidesStep.sideA,
    this.sideA = '',
    this.twoSidesMessages = const [],
  });

  final ChatMode mode;
  final List<ChatMessage> askMessages;
  final TwoSidesStep twoSidesStep;

  /// Driver's own account, kept while answering step B.
  final String sideA;
  final List<ChatMessage> twoSidesMessages;

  List<ChatMessage> get visibleMessages =>
      mode == ChatMode.ask ? askMessages : twoSidesMessages;

  bool get streaming =>
      [...askMessages, ...twoSidesMessages].any((m) => m.streaming);

  ChatState copyWith({
    ChatMode? mode,
    List<ChatMessage>? askMessages,
    TwoSidesStep? twoSidesStep,
    String? sideA,
    List<ChatMessage>? twoSidesMessages,
  }) => ChatState(
    mode: mode ?? this.mode,
    askMessages: askMessages ?? this.askMessages,
    twoSidesStep: twoSidesStep ?? this.twoSidesStep,
    sideA: sideA ?? this.sideA,
    twoSidesMessages: twoSidesMessages ?? this.twoSidesMessages,
  );
}

/// Chat + "Dalawang panig" state. autoDispose: history clears when the
/// screen closes.
class ChatController extends AutoDisposeNotifier<ChatState> {
  StreamSubscription<String>? _sub;

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ChatState();
  }

  void setMode(ChatMode mode) {
    if (state.streaming) return;
    state = state.copyWith(mode: mode);
  }

  /// Ask mode: send a question.
  /// Agency of an open "Ano ang sinabing violation?" question; the next
  /// typed message is matched against that agency's fines.
  Agency? _awaitingViolation;

  void ask(String question) {
    final q = question.trim();
    if (q.isEmpty || state.streaming) return;
    final awaiting = _awaitingViolation;
    // A long new question leaves the flow instead of being matched.
    if (awaiting != null && q.split(RegExp(r'\s+')).length <= 10) {
      answerViolation(q, awaiting);
      return;
    }
    _awaitingViolation = null;
    if (isFlaggedWithoutViolation(q)) {
      _askWhichViolation(q);
      return;
    }
    state = state.copyWith(
      askMessages: [
        ...state.askMessages,
        ChatMessage(role: ChatRole.user, text: q),
        const ChatMessage(role: ChatRole.buddy, text: '', streaming: true),
      ],
    );
    _listen(ref.read(aiAssistantProvider).ask(q));
  }

  /// Flagged without a violation: ask which one, with the agency's most
  /// common violations as chips.
  Future<void> _askWhichViolation(String q) async {
    final agency = detectAgency(q);
    _pushExchange(q);
    final all = await ref.read(finesRepositoryProvider).search('', agency);
    _awaitingViolation = agency;
    _updateStreaming(
      (m) => m.copyWith(
        text: '$flagQuestion\n$flagQuestionHint',
        streaming: false,
        flag: FlagStep.askViolation,
        agency: agency,
        chips: commonViolations(all),
      ),
    );
  }

  /// The driver named the violation (typed or chip): match it with the
  /// Na-flag fine search for [agency].
  Future<void> answerViolation(String text, Agency agency) async {
    final q = text.trim();
    if (q.isEmpty || state.streaming) return;
    _pushExchange(q);
    final repo = ref.read(finesRepositoryProvider);
    final found = await repo.search(q, agency);
    if (found.isNotEmpty) {
      _awaitingViolation = null;
      final fine = found.first;
      _updateStreaming(
        (m) => m.copyWith(
          text:
              'Ito ang multa para sa "${violationLabel(fine)}" '
              '(${agency.name.toUpperCase()}):',
          streaming: false,
          flag: FlagStep.fine,
          agency: agency,
          fine: fine,
        ),
      );
    } else {
      _awaitingViolation = agency;
      final all = await repo.search('', agency);
      _updateStreaming(
        (m) => m.copyWith(
          text: '$flagNoMatch\n$flagQuestionHint',
          streaming: false,
          flag: FlagStep.noMatch,
          agency: agency,
          chips: commonViolations(all),
        ),
      );
    }
  }

  /// User message + an empty, "typing" Buddy message (dots, then reveal).
  void _pushExchange(String q) {
    state = state.copyWith(
      askMessages: [
        ...state.askMessages,
        ChatMessage(role: ChatRole.user, text: q),
        const ChatMessage(role: ChatRole.buddy, text: '', streaming: true),
      ],
    );
  }

  /// Two sides, step A → B.
  void submitSideA(String text) {
    final a = text.trim();
    if (a.isEmpty) return;
    state = state.copyWith(sideA: a, twoSidesStep: TwoSidesStep.sideB);
  }

  /// Two sides, step B → "Suriin".
  void analyze(String sideB) {
    final b = sideB.trim();
    if (b.isEmpty || state.sideA.isEmpty || state.streaming) return;
    state = state.copyWith(
      twoSidesStep: TwoSidesStep.result,
      twoSidesMessages: [
        ChatMessage(role: ChatRole.user, text: state.sideA, label: 'Panig mo'),
        ChatMessage(role: ChatRole.user, text: b, label: 'Kabilang driver'),
        const ChatMessage(role: ChatRole.buddy, text: '', streaming: true),
      ],
    );
    _listen(ref.read(aiAssistantProvider).analyzeTwoSides(state.sideA, b));
  }

  /// Back from step B to A (keeps what was typed for A).
  void backToSideA() =>
      state = state.copyWith(twoSidesStep: TwoSidesStep.sideA);

  /// "Bagong kaso".
  void newCase() {
    if (state.streaming) stop();
    state = state.copyWith(
      twoSidesStep: TwoSidesStep.sideA,
      sideA: '',
      twoSidesMessages: const [],
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _updateStreaming((m) => m.copyWith(streaming: false, stopped: true));
  }

  void _listen(Stream<String> stream) {
    _sub?.cancel();
    _sub = stream.listen(
      (chunk) => _updateStreaming((m) => m.copyWith(text: m.text + chunk)),
      onError: (Object _) =>
          _updateStreaming((m) => m.copyWith(streaming: false, failed: true)),
      onDone: () => _updateStreaming((m) => m.copyWith(streaming: false)),
      cancelOnError: true,
    );
  }

  /// Applies [update] to whichever message is currently streaming.
  void _updateStreaming(ChatMessage Function(ChatMessage) update) {
    List<ChatMessage> apply(List<ChatMessage> list) => [
      for (final m in list) m.streaming ? update(m) : m,
    ];
    state = state.copyWith(
      askMessages: apply(state.askMessages),
      twoSidesMessages: apply(state.twoSidesMessages),
    );
  }
}

final chatControllerProvider =
    NotifierProvider.autoDispose<ChatController, ChatState>(ChatController.new);

/// Suggestion cards for an empty chat; tap sends the question.
const quickQuestions = [
  'Magkano multa pag walang helmet?',
  'Pwede ba mag-overtake sa double yellow?',
  'Nabangga ako, sino may mali?',
  'Na-flag ako ng MMDA, ano gagawin?',
];
