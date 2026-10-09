import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

enum ChatRole { user, buddy }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.label,
    this.streaming = false,
    this.stopped = false,
    this.failed = false,
  });

  final ChatRole role;
  final String text;

  /// Small caption above a user bubble, e.g. "Panig mo".
  final String? label;
  final bool streaming;
  final bool stopped;
  final bool failed;

  ChatMessage copyWith({
    String? text,
    bool? streaming,
    bool? stopped,
    bool? failed,
  }) => ChatMessage(
    role: role,
    text: text ?? this.text,
    label: label,
    streaming: streaming ?? this.streaming,
    stopped: stopped ?? this.stopped,
    failed: failed ?? this.failed,
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
  void ask(String question) {
    final q = question.trim();
    if (q.isEmpty || state.streaming) return;
    state = state.copyWith(
      askMessages: [
        ...state.askMessages,
        ChatMessage(role: ChatRole.user, text: q),
        const ChatMessage(role: ChatRole.buddy, text: '', streaming: true),
      ],
    );
    _listen(ref.read(aiAssistantProvider).ask(q));
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
