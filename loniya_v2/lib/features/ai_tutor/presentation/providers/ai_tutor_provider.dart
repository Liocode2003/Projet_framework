import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/database/database_service.dart';
import '../../data/datasources/ai_tutor_local_datasource.dart';
import '../../data/repositories/ai_tutor_repository_impl.dart';
import '../../data/services/ai_tutor_engine.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/repositories/ai_tutor_repository.dart';
import '../../domain/usecases/ask_question_usecase.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────
final aiTutorEngineProvider = Provider<AiTutorEngine>((_) => AiTutorEngine());

final aiTutorLocalDataSourceProvider =
    Provider<AiTutorLocalDataSource>((ref) {
  return AiTutorLocalDataSource(
    ref.read(databaseServiceProvider),
    ref.read(aiTutorEngineProvider),
  );
});

final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepositoryImpl(ref.read(aiTutorLocalDataSourceProvider));
});

final askQuestionUseCaseProvider = Provider(
  (ref) => AskQuestionUseCase(ref.read(aiTutorRepositoryProvider)),
);

// ─── Context provider (set from lesson step) ──────────────────────────────────
final aiTutorContextProvider = StateProvider<AiContext?>((ref) => null);

// ─── Chat state ───────────────────────────────────────────────────────────────
class AiTutorState {
  final List<AiMessageEntity> messages;
  final bool isTyping;
  final String? errorMessage;

  const AiTutorState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  AiTutorState copyWith({
    List<AiMessageEntity>? messages,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AiTutorState(
        messages:     messages ?? this.messages,
        isTyping:     isTyping ?? this.isTyping,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Chat notifier ────────────────────────────────────────────────────────────
class AiTutorNotifier extends StateNotifier<AiTutorState> {
  final Ref _ref;
  static const _uuid = Uuid();
  // Simulated "thinking" delay — makes it feel natural, low overhead
  static const _thinkingMs = 800;

  AiTutorNotifier(this._ref) : super(const AiTutorState()) {
    // Prune expired cache on init
    _ref.read(aiTutorRepositoryProvider).pruneCache();
    // Greet the user
    _addTutorMessage(_greeting());
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Append user message
    _addUserMessage(trimmed);

    // 2. Show typing indicator
    state = state.copyWith(isTyping: true, clearError: true);

    // 3. Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: _thinkingMs));

    // 4. Ask use case
    final context = _ref.read(aiTutorContextProvider);
    final userId  = _ref.read(currentUserProvider)?.id ?? '';

    final result = await _ref.read(askQuestionUseCaseProvider).call(
      userId:       userId,
      question:     trimmed,
      stepId:       context?.stepId ?? '',
      stepKeywords: context?.keywords ?? [],
      subject:      context?.subject ?? '',
    );

    state = state.copyWith(isTyping: false);

    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure.message,
      ),
      (response) => _addTutorMessage(response),
    );
  }

  void clearContext() {
    _ref.read(aiTutorContextProvider.notifier).state = null;
  }

  void clearChat() {
    state = const AiTutorState();
    _addTutorMessage(_greeting());
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _addUserMessage(String text) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        AiMessageEntity(
          id:        _uuid.v4(),
          role:      MessageRole.user,
          content:   text,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  void _addTutorMessage(String text) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        AiMessageEntity(
          id:        _uuid.v4(),
          role:      MessageRole.tutor,
          content:   text,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  String _greeting() =>
      'Bonjour ! Je suis LONIYA, ton tuteur IA. 🌟\n'
      'Je suis là pour t\'aider à comprendre — pas pour te donner les réponses directement.\n'
      'Pose-moi une question sur ta leçon !';
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final aiTutorNotifierProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>(
  (ref) => AiTutorNotifier(ref),
);
