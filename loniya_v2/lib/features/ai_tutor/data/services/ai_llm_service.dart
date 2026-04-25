import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../../domain/entities/ai_message_entity.dart';

/// Groq API client.
/// - Text chat : llama-3.3-70b-versatile (primary) / llama-3.1-8b-instant (fallback)
/// - Vision    : meta-llama/llama-4-scout-17b-16e-instruct
/// - Audio STT : whisper-large-v3-turbo
class AiLlmService {
  final SecureKeyService _keys;

  static const _endpoint       = 'https://api.groq.com/openai/v1/chat/completions';
  static const _whisperEndpoint = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const _modelPrimary   = 'llama-3.3-70b-versatile';
  static const _modelFast      = 'llama-3.1-8b-instant';
  static const _modelVision    = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _modelWhisper   = 'whisper-large-v3-turbo';
  static const _timeout        = Duration(seconds: 25);
  static const _maxTokens      = 200;
  static const _maxHistory     = 10;

  AiLlmService(this._keys);

  // ─── Text chat ──────────────────────────────────────────────────────────────

  Future<Either<Failure, String>> chat({
    required String question,
    required List<AiMessageEntity> history,
    String userRole   = 'student',
    String grade      = '',
    String subject    = '',
    String stepTitle  = '',
    List<String> stepKeywords = const [],
  }) async {
    final apiKey = await _keys.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const Left(AuthFailure('Clé API Groq non configurée.'));
    }

    final messages = _buildTextPayload(
      question: question, history: history,
      userRole: userRole, grade: grade,
      subject: subject, stepTitle: stepTitle,
      stepKeywords: stepKeywords,
    );

    for (final model in [_modelPrimary, _modelFast]) {
      final result = await _postText(
        apiKey: apiKey.trim(), model: model, messages: messages);
      if (result.isLeft()) {
        final failure = result.fold((f) => f, (_) => null);
        if (failure is AuthFailure) return result;
        if (failure is ServerFailure && model == _modelFast) return result;
        continue;
      }
      return result;
    }
    return const Left(OfflineFailure());
  }

  // ─── Vision chat (image + optional text) ───────────────────────────────────

  Future<Either<Failure, String>> chatWithImage({
    required String imagePath,
    required String prompt,
    String userRole = 'student',
    String grade    = '',
    String subject  = '',
  }) async {
    final apiKey = await _keys.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const Left(AuthFailure('Clé API Groq non configurée.'));
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final ext = imagePath.toLowerCase().split('.').last;
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      final userText = prompt.trim().isEmpty
          ? 'Analyse cette image et aide-moi à comprendre ce qu\'elle montre.'
          : prompt.trim();

      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': _systemPrompt(
            userRole: userRole, grade: grade,
            subject: subject, stepTitle: '', stepKeywords: [],
          ),
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$base64Image'},
            },
            {'type': 'text', 'text': userText},
          ],
        },
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${apiKey.trim()}',
        },
        body: jsonEncode({
          'model': _modelVision,
          'messages': messages,
          'temperature': 0.70,
          'max_tokens': _maxTokens,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          return const Left(ServerFailure('Réponse invalide de l\'IA.'));
        }
        final content = choices.first['message']['content'] as String;
        return Right(content.trim());
      }
      if (response.statusCode == 401) {
        return const Left(AuthFailure('Clé API invalide ou expirée.'));
      }
      return Left(ServerFailure('Groq vision ${response.statusCode}'));
    } on TimeoutException {
      return const Left(OfflineFailure());
    } on SocketException {
      return const Left(OfflineFailure());
    } catch (_) {
      return const Left(OfflineFailure());
    }
  }

  // ─── Audio transcription (Whisper) ─────────────────────────────────────────

  Future<Either<Failure, String>> transcribeAudio(String filePath) async {
    final apiKey = await _keys.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const Left(AuthFailure('Clé API Groq non configurée.'));
    }

    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse(_whisperEndpoint));
      request.headers['Authorization'] = 'Bearer ${apiKey.trim()}';
      request.fields['model']           = _modelWhisper;
      request.fields['language']        = 'fr';
      request.fields['response_format'] = 'text';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final text = response.body.trim();
        if (text.isEmpty) {
          return const Left(ServerFailure('Audio non reconnu — réessaie.'));
        }
        return Right(text);
      }
      if (response.statusCode == 401) {
        return const Left(AuthFailure('Clé API invalide ou expirée.'));
      }
      return Left(ServerFailure('Whisper ${response.statusCode}'));
    } on TimeoutException {
      return const Left(OfflineFailure());
    } on SocketException {
      return const Left(OfflineFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Internal helpers ───────────────────────────────────────────────────────

  Future<Either<Failure, String>> _postText({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.70,
          'max_tokens': _maxTokens,
          'stream': false,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          return const Left(ServerFailure('Réponse invalide de l\'IA.'));
        }
        final content = choices.first['message']['content'] as String;
        return Right(content.trim());
      }
      if (response.statusCode == 401) {
        return const Left(AuthFailure('Clé API invalide ou expirée.'));
      }
      if (response.statusCode == 429) {
        return const Left(ServerFailure('Limite de requêtes — réessaie dans quelques secondes.'));
      }
      return Left(ServerFailure('Groq ${response.statusCode}'));
    } on TimeoutException {
      return const Left(OfflineFailure());
    } on SocketException {
      return const Left(OfflineFailure());
    } catch (_) {
      return const Left(OfflineFailure());
    }
  }

  List<Map<String, String>> _buildTextPayload({
    required String question,
    required List<AiMessageEntity> history,
    required String userRole,
    required String grade,
    required String subject,
    required String stepTitle,
    required List<String> stepKeywords,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(
        userRole: userRole, grade: grade,
        subject: subject, stepTitle: stepTitle,
        stepKeywords: stepKeywords,
      )},
    ];

    final recent = history.length > _maxHistory
        ? history.sublist(history.length - _maxHistory)
        : history;
    for (final msg in recent) {
      // Only include text messages in history
      if (msg.type == AiMessageType.text) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    messages.add({'role': 'user', 'content': question});
    return messages;
  }

  String _systemPrompt({
    required String userRole,
    required String grade,
    required String subject,
    required String stepTitle,
    required List<String> stepKeywords,
  }) {
    final profile = switch (userRole) {
      'teacher' => 'Tu parles à un enseignant${subject.isNotEmpty ? " de $subject" : ""}.',
      'parent'  => 'Tu parles à un parent d\'élève.',
      _         => 'Tu parles à un élève burkinabè'
                   '${grade.isNotEmpty ? " de classe $grade" : ""}'
                   '${subject.isNotEmpty ? ", matière : $subject" : ""}.',
    };

    final context = stepTitle.isNotEmpty
        ? '\nLeçon en cours : "$stepTitle"'
          '${stepKeywords.isNotEmpty ? " — mots-clés : ${stepKeywords.join(", ")}" : ""}.'
        : '';

    return '''Tu es Le Sage, tuteur pédagogique intelligent pour le système éducatif du Burkina Faso. $profile$context

Règles impératives :
1. Méthode socratique : guide par questions et indices — ne donne JAMAIS la réponse directement.
2. Langue : français correct et adapté au niveau scolaire. Sois chaleureux, bienveillant, encourageant.
3. Concision : 2 à 4 phrases maximum. Pas de listes à puces, parle naturellement.
4. Si l'élève réclame la réponse directement : reformule une question de relance stimulante.
5. Si un contexte de leçon est fourni : utilise ses mots-clés comme fil conducteur.
6. Adapte la complexité : simple et imagé pour le primaire, rigoureux pour le lycée.
7. Tu peux mentionner des exemples de la vie quotidienne au Burkina Faso pour ancrer les concepts.
8. Si une image est partagée : décris ce que tu observes et pose des questions pédagogiques à l'élève.''';
  }
}
