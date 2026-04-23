import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../../data/datasources/ai_tutor_local_datasource.dart';
import '../../data/repositories/ai_tutor_repository_impl.dart';
import '../../data/services/ai_llm_service.dart';
import '../../data/services/ai_tutor_engine.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/repositories/ai_tutor_repository.dart';
import '../../domain/usecases/ask_question_usecase.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────
final aiTutorEngineProvider = Provider<AiTutorEngine>((_) => AiTutorEngine());

final aiLlmServiceProvider = Provider<AiLlmService>((ref) {
  return AiLlmService(ref.read(secureKeyServiceProvider));
});

final aiTutorLocalDataSourceProvider =
    Provider<AiTutorLocalDataSource>((ref) {
  return AiTutorLocalDataSource(
    ref.read(databaseServiceProvider),
    ref.read(aiTutorEngineProvider),
  );
});

final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepositoryImpl(
    ref.read(aiTutorLocalDataSourceProvider),
    ref.read(aiLlmServiceProvider),
    ref.read(connectivityServiceProvider),
  );
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
    this.messages     = const [],
    this.isTyping     = false,
    this.errorMessage,
  });

  AiTutorState copyWith({
    List<AiMessageEntity>? messages,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AiTutorState(
        messages:     messages     ?? this.messages,
        isTyping:     isTyping     ?? this.isTyping,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Chat notifier ────────────────────────────────────────────────────────────
class AiTutorNotifier extends StateNotifier<AiTutorState> {
  final Ref _ref;
  static const _uuid = Uuid();

  AiTutorNotifier(this._ref) : super(const AiTutorState()) {
    _ref.read(aiTutorRepositoryProvider).pruneCache();
    _addTutorMessage(_greeting());
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _addUserMessage(trimmed);
    state = state.copyWith(isTyping: true, clearError: true);

    // Natural thinking delay — shorter online (LLM responds quickly)
    final isOnline = _ref.read(connectivityServiceProvider).isConnected;
    await Future.delayed(Duration(milliseconds: isOnline ? 400 : 700));

    final aiContext = _ref.read(aiTutorContextProvider);
    final user      = _ref.read(currentUserProvider);

    final result = await _ref.read(askQuestionUseCaseProvider).call(
      userId:       user?.id ?? '',
      question:     trimmed,
      // Pass conversation history (exclude the message just added)
      history:      state.messages.where((m) => m.content != trimmed || m.isUser == false).toList(),
      stepId:       aiContext?.stepId    ?? '',
      stepKeywords: aiContext?.keywords  ?? [],
      subject:      aiContext?.subject   ?? user?.gradeLevel ?? '',
      userRole:     user?.role           ?? 'student',
      grade:        user?.gradeLevel     ?? '',
      stepTitle:    aiContext?.stepTitle ?? '',
    );

    state = state.copyWith(isTyping: false);

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
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
    state = state.copyWith(messages: [
      ...state.messages,
      AiMessageEntity(
        id:        _uuid.v4(),
        role:      MessageRole.user,
        content:   text,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  void _addTutorMessage(String text) {
    state = state.copyWith(messages: [
      ...state.messages,
      AiMessageEntity(
        id:        _uuid.v4(),
        role:      MessageRole.tutor,
        content:   text,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  String _greeting() =>
      'Bonjour ! Je suis LONIYA IA 🌟\n'
      'Je suis là pour t\'aider à comprendre, pas te donner les réponses.\n'
      'Pose-moi une question sur ta leçon !';
}

// ─── Providers ────────────────────────────────────────────────────────────────
final aiTutorNotifierProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>(
  (ref) => AiTutorNotifier(ref),
);

/// True when Groq API key is configured.
final hasApiKeyProvider = FutureProvider<bool>((ref) async {
  final key = await ref.read(secureKeyServiceProvider).getApiKey();
  return key != null && key.trim().isNotEmpty;
});
