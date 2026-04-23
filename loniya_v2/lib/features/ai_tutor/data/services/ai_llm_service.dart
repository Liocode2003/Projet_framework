import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/secure_key_service.dart';
import '../../domain/entities/ai_message_entity.dart';

/// Groq API client — uses llama-3.3-70b-versatile for fast, free inference.
/// Requires a Groq API key (free at console.groq.com).
class AiLlmService {
  final SecureKeyService _keys;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model    = 'llama-3.3-70b-versatile';
  static const _timeout  = Duration(seconds: 25);
  static const _maxHistory = 12;

  AiLlmService(this._keys);

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

    try {
      final messages = _buildPayload(
        question: question,
        history: history,
        userRole: userRole,
        grade: grade,
        subject: subject,
        stepTitle: stepTitle,
        stepKeywords: stepKeywords,
      );

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.72,
              'max_tokens': 256,
              'stream': false,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['choices'] as List).first['message']['content'] as String;
        return Right(content.trim());
      }

      if (response.statusCode == 401) {
        return const Left(AuthFailure('Clé API invalide ou expirée.'));
      }
      if (response.statusCode == 429) {
        return const Left(ServerFailure('Limite de requêtes atteinte — réessaie dans quelques secondes.'));
      }
      return Left(ServerFailure('Erreur Groq (${response.statusCode}).'));
    } on TimeoutException {
      return const Left(OfflineFailure());
    } catch (e) {
      return Left(UnknownFailure('Erreur réseau : $e'));
    }
  }

  List<Map<String, String>> _buildPayload({
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
        userRole: userRole,
        grade: grade,
        subject: subject,
        stepTitle: stepTitle,
        stepKeywords: stepKeywords,
      )},
    ];

    // Append recent history (skip greeting messages from tutor init)
    final recent = history.length > _maxHistory
        ? history.sublist(history.length - _maxHistory)
        : history;
    for (final msg in recent) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      });
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

    return '''Tu es LONIYA IA, tuteur pédagogique intelligent pour le système éducatif du Burkina Faso. $profile$context

Règles impératives :
1. Méthode socratique : guide par questions et indices — ne donne JAMAIS la réponse directement.
2. Langue : français correct et adapté au niveau scolaire. Sois chaleureux, bienveillant, encourageant.
3. Concision : 2 à 4 phrases maximum. Pas de listes à puces, parle naturellement.
4. Si l'élève réclame la réponse directement : reformule une question de relance stimulante.
5. Si un contexte de leçon est fourni : utilise ses mots-clés comme fil conducteur.
6. Adapte la complexité : simple et imagé pour le primaire, rigoureux pour le lycée.
7. Tu peux mentionner des exemples de la vie quotidienne au Burkina Faso pour ancrer les concepts.''';
  }
}
