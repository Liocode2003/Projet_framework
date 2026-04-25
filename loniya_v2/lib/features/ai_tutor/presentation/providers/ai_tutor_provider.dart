import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/errors/failures.dart';
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
import '../../../homework/presentation/providers/homework_provider.dart';

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
  /// ID of the last tutor message that is fully ready (streaming done or
  /// non-streamed). Listeners use this to trigger TTS exactly once per reply.
  final String? readyTutorId;

  const AiTutorState({
    this.messages     = const [],
    this.isTyping     = false,
    this.errorMessage,
    this.readyTutorId,
  });

  AiTutorState copyWith({
    List<AiMessageEntity>? messages,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
    String? readyTutorId,
    bool clearReadyTutor = false,
  }) =>
      AiTutorState(
        messages:     messages     ?? this.messages,
        isTyping:     isTyping     ?? this.isTyping,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        readyTutorId: clearReadyTutor ? null : (readyTutorId ?? this.readyTutorId),
      );
}

// ─── Chat notifier ────────────────────────────────────────────────────────────
class AiTutorNotifier extends StateNotifier<AiTutorState> {
  final Ref _ref;
  static const _uuid       = Uuid();
  static const _historyKey = 'chat_history';

  AiTutorNotifier(this._ref) : super(const AiTutorState()) {
    _ref.read(aiTutorRepositoryProvider).pruneCache().ignore();
    if (!_loadHistory()) _addTutorMessage(_greeting());
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _addUserMessage(trimmed);
    state = state.copyWith(isTyping: true, clearError: true);

    final isOnline    = _ref.read(connectivityServiceProvider).isConnected;
    final aiContext   = _ref.read(aiTutorContextProvider);
    final user        = _ref.read(currentUserProvider);

    if (!isOnline) {
      // Offline: serve from local AI cache if available
      await Future.delayed(const Duration(milliseconds: 700));
      final result = await _ref.read(askQuestionUseCaseProvider).call(
        userId:       user?.id         ?? '',
        question:     trimmed,
        history:      state.messages.sublist(0, state.messages.length - 1),
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
        (response) { _addTutorMessage(response); _saveHistory(); },
      );
      return;
    }

    // Online: stream tokens into a live bubble
    state = state.copyWith(isTyping: false);
    final tutorMsgId = _uuid.v4();
    _addEmptyTutorMessage(tutorMsgId);

    // Snapshot history before the new user message and the empty tutor bubble
    final historySnapshot =
        state.messages.sublist(0, state.messages.length - 2);

    final stream = _ref.read(aiLlmServiceProvider).chatStream(
      question:     trimmed,
      history:      historySnapshot,
      userRole:     user?.role           ?? 'student',
      grade:        user?.gradeLevel     ?? '',
      subject:      aiContext?.subject   ?? user?.gradeLevel ?? '',
      stepTitle:    aiContext?.stepTitle ?? '',
      stepKeywords: aiContext?.keywords  ?? [],
    );

    bool gotContent = false;
    await for (final chunk in stream) {
      chunk.fold(
        (failure) {
          if (!gotContent) {
            _removeTutorMessage(tutorMsgId);
            state = state.copyWith(errorMessage: failure.message);
          }
        },
        (token) {
          gotContent = true;
          _appendToTutorMessage(tutorMsgId, token);
        },
      );
    }
    if (gotContent) {
      // Signal TTS that this message is fully streamed
      state = state.copyWith(readyTutorId: tutorMsgId);
      _saveHistory();
    }
  }

  /// Send an image to Le Sage. Shows image in chat then calls vision API.
  Future<void> sendImageMessage(String imagePath, {String caption = ''}) async {
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
      (response) { _addTutorMessage(response); _saveHistory(); },
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

    // Extract synchronously — avoids async closure inside fold()
    final failure    = result.fold((f) => f, (_) => null);
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

  /// Generates a BEPC/BAC success prediction from the student's in-app data.
  Future<void> predictExamResult(String examName) async {
    final user       = _ref.read(currentUserProvider);
    final homework   = _ref.read(homeworkProvider);
    final grade      = user?.gradeLevel ?? (examName == 'BAC' ? 'Terminale' : '3ème');

    final done    = homework.where((h) => h.isDone).toList();
    final scored  = done.where((h) => h.score != null).toList();
    final avgScore = scored.isEmpty
        ? 0.0
        : scored.map((h) => h.score!).reduce((a, b) => a + b) / scored.length;

    // Derive weak/strong subjects from scored homework
    final subjectScores = <String, List<int>>{};
    for (final h in scored) {
      subjectScores.putIfAbsent(h.subject, () => []).add(h.score!);
    }
    final subjectAvg = subjectScores.map(
      (s, scores) => MapEntry(s, scores.reduce((a, b) => a + b) / scores.length));
    final weakSubjects   = subjectAvg.entries
        .where((e) => e.value < 10).map((e) => e.key).toList();
    final strongSubjects = subjectAvg.entries
        .where((e) => e.value >= 14).map((e) => e.key).toList();

    final totalSessions = state.messages.where((m) => m.isUser).length;

    state = state.copyWith(isTyping: true, clearError: true);

    final result = await _ref.read(aiLlmServiceProvider).predictExamResult(
      examName:       examName,
      grade:          grade,
      totalSessions:  totalSessions,
      homeworkDone:   done.length,
      homeworkTotal:  homework.length,
      avgScore:       avgScore,
      quizCorrect:    0,
      quizTotal:      0,
      weakSubjects:   weakSubjects,
      strongSubjects: strongSubjects,
    );

    state = state.copyWith(isTyping: false);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (prediction) { _addTutorMessage(prediction); _saveHistory(); },
    );
  }

  /// Called when the user sends a copy-pasted message.
  /// Le Sage refuses and requires the student to rephrase in their own words.
  void handleCopiedMessage(String pastedText) {
    _addUserMessage(pastedText);
    const refusals = [
      'Tu viens de copier cette question. Je ne répondrai pas. '
      'Pose-la avec tes propres mots — c\'est comme ça qu\'on apprend vraiment. 🌿',
      'Hmm, cette question a été copiée quelque part. Je préfère que tu me dises, '
      'avec tes propres mots, ce que TU veux comprendre. 😊',
      'Je remarque que tu as collé ce texte. Reformule-le à ta façon : '
      'qu\'est-ce qui te pose problème exactement ? 🤔',
    ];
    final idx = state.messages.length % refusals.length;
    _addTutorMessage(refusals[idx]);
    _saveHistory();
  }

  void clearContext() {
    _ref.read(aiTutorContextProvider.notifier).state = null;
  }

  void clearChat() {
    Hive.box(HiveBoxes.aiCache).delete(_historyKey);
    state = const AiTutorState();
    _addTutorMessage(_greeting());
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  bool _loadHistory() {
    try {
      final raw =
          Hive.box(HiveBoxes.aiCache).get(_historyKey) as String?;
      if (raw == null || raw.isEmpty) return false;
      final list = jsonDecode(raw) as List<dynamic>;
      if (list.isEmpty) return false;
      final messages = list
          .whereType<Map<String, dynamic>>()
          .map(_msgFromJson)
          .toList();
      if (messages.isEmpty) return false;
      state = state.copyWith(messages: messages);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _saveHistory() {
    try {
      final json = jsonEncode(state.messages.map(_msgToJson).toList());
      Hive.box(HiveBoxes.aiCache).put(_historyKey, json);
    } catch (_) {}
  }

  static Map<String, dynamic> _msgToJson(AiMessageEntity m) => {
    'id':             m.id,
    'role':           m.role.name,
    'content':        m.content,
    'createdAt':      m.createdAt.toIso8601String(),
    'fromCache':      m.fromCache,
    'type':           m.type.name,
    'attachmentPath': m.attachmentPath,
  };

  static AiMessageEntity _msgFromJson(Map<String, dynamic> j) => AiMessageEntity(
    id:             j['id'] as String,
    role:           MessageRole.values.byName(j['role'] as String),
    content:        j['content'] as String,
    createdAt:      DateTime.parse(j['createdAt'] as String),
    fromCache:      j['fromCache'] as bool? ?? false,
    type:           AiMessageType.values.byName(j['type'] as String? ?? 'text'),
    attachmentPath: j['attachmentPath'] as String?,
  );

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

  void _addEmptyTutorMessage(String id) {
    state = state.copyWith(messages: [
      ...state.messages,
      AiMessageEntity(
        id:        id,
        role:      MessageRole.tutor,
        content:   '',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  void _appendToTutorMessage(String id, String token) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != id) return m;
        return AiMessageEntity(
          id:             m.id,
          role:           m.role,
          content:        m.content + token,
          createdAt:      m.createdAt,
          type:           m.type,
          attachmentPath: m.attachmentPath,
        );
      }).toList(),
    );
  }

  void _removeTutorMessage(String id) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != id).toList(),
    );
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
    final id = _uuid.v4();
    state = state.copyWith(
      messages: [
        ...state.messages,
        AiMessageEntity(
          id:        id,
          role:      MessageRole.tutor,
          content:   text,
          createdAt: DateTime.now(),
        ),
      ],
      readyTutorId: id,
    );
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
