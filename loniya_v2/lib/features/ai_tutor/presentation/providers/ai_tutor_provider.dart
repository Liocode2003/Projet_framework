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
import '../../../../core/errors/failures.dart';

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

    final isOnline = _ref.read(connectivityServiceProvider).isConnected;
    await Future.delayed(Duration(milliseconds: isOnline ? 400 : 700));

    final aiContext = _ref.read(aiTutorContextProvider);
    final user      = _ref.read(currentUserProvider);

    final result = await _ref.read(askQuestionUseCaseProvider).call(
      userId:       user?.id ?? '',
      question:     trimmed,
      history:      state.messages.where((m) => m.content != trimmed || !m.isUser).toList(),
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

  /// Send an image to Le Sage. Shows image in chat then calls vision API.
  Future<void> sendImageMessage(String imagePath, {String caption = ''}) async {
    // Guard: vision requires an active internet connection
    final isOnline = _ref.read(connectivityServiceProvider).isConnected;
    if (!isOnline) {
      state = state.copyWith(
        errorMessage: 'Analyse d\'image indisponible hors-ligne. '
            'Connecte-toi à internet pour utiliser la vision IA.',
      );
      return;
    }

    _addAttachmentMessage(
      content:        caption.trim().isEmpty ? '📷 Image envoyée' : caption.trim(),
      type:           AiMessageType.image,
      attachmentPath: imagePath,
    );
    state = state.copyWith(isTyping: true, clearError: true);

    await Future.delayed(const Duration(milliseconds: 500));

    final user = _ref.read(currentUserProvider);
    final llm  = _ref.read(aiLlmServiceProvider);

    final result = await llm.chatWithImage(
      imagePath: imagePath,
      prompt:    caption.trim(),
      userRole:  user?.role        ?? 'student',
      grade:     user?.gradeLevel  ?? '',
      subject:   _ref.read(aiTutorContextProvider)?.subject ?? '',
    );

    state = state.copyWith(isTyping: false);
    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure is AuthFailure
            ? failure.message
            : 'Analyse d\'image indisponible hors-ligne.',
      ),
      (response) => _addTutorMessage(response),
    );
  }

  /// Transcribe audio then send transcription as a regular message.
  Future<void> sendAudioMessage(String audioPath) async {
    _addAttachmentMessage(
      content:        '🎤 Message vocal',
      type:           AiMessageType.audio,
      attachmentPath: audioPath,
    );
    state = state.copyWith(isTyping: true, clearError: true);

    final llm    = _ref.read(aiLlmServiceProvider);
    final result = await llm.transcribeAudio(audioPath);

    // Extract transcript synchronously — avoids async closure inside fold()
    final failure   = result.fold((f) => f, (_) => null);
    final transcript = result.fold((_) => null, (t) => t);

    if (failure != null) {
      state = state.copyWith(
        isTyping: false,
        errorMessage: failure is AuthFailure
            ? failure.message
            : 'Transcription indisponible hors-ligne.',
      );
      return;
    }

    if (transcript == null || transcript.trim().isEmpty) {
      state = state.copyWith(
        isTyping: false,
        errorMessage: 'Audio non reconnu — réessaie.',
      );
      return;
    }

    // Update audio bubble to show the transcribed text
    final updated = state.messages.map((m) {
      if (m.attachmentPath == audioPath) {
        return AiMessageEntity(
          id:             m.id,
          role:           m.role,
          content:        '🎤 "$transcript"',
          createdAt:      m.createdAt,
          type:           AiMessageType.audio,
          attachmentPath: audioPath,
        );
      }
      return m;
    }).toList();
    // Keep isTyping: true — sendMessage manages typing state from here
    state = state.copyWith(messages: updated);

    await sendMessage(transcript);
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

  void _addAttachmentMessage({
    required String content,
    required AiMessageType type,
    required String attachmentPath,
  }) {
    state = state.copyWith(messages: [
      ...state.messages,
      AiMessageEntity(
        id:             _uuid.v4(),
        role:           MessageRole.user,
        content:        content,
        createdAt:      DateTime.now(),
        type:           type,
        attachmentPath: attachmentPath,
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
      'Bonjour ! Je suis Le Sage 🌿\n'
      'Je suis là pour t\'aider à comprendre, pas te donner les réponses.\n'
      'Pose-moi une question, envoie une photo de ton exercice, ou parle-moi !';
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
