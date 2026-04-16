import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// Rule-based Socratic hint engine.
/// Matches user question tokens against keyword rules from JSON asset,
/// then returns a hint (never a direct answer) in ≤ 3 sentences.
class AiTutorEngine {
  static const _assetPath = 'assets/mock_data/ai_tutor_rules.json';
  static const _maxSentences = 3;
  static const _cacheMaxAgeHours = 72;

  _AiRules? _rules;
  final Random _rng = Random();

  /// Loads and caches the rules asset.
  Future<_AiRules> _loadRules() async {
    if (_rules != null) return _rules!;
    final raw = await rootBundle.loadString(_assetPath);
    _rules = _AiRules.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _rules!;
  }

  /// Generates a Socratic hint for [question].
  /// [stepKeywords] are the current lesson step's keyword tags (priority boost).
  Future<String> generate({
    required String question,
    List<String> stepKeywords = const [],
    String subject = '',
  }) async {
    final rules = await _loadRules();
    final tokens = _tokenize(question);

    // Detect "give me the answer" requests → polite refusal first
    if (_asksForDirectAnswer(tokens)) {
      final hint = _pickHint(rules.defaultRule, question);
      return '${rules.noDirectAnswerMessage}\n\n$hint';
    }

    // Score each rule
    final scored = <_ScoredRule>[];
    for (final rule in rules.rules) {
      final score = _score(tokens, rule.tags, stepKeywords);
      if (score > 0) scored.add(_ScoredRule(rule, score));
    }

    // Sort by score descending; pick top rule (fallback to default)
    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.isNotEmpty ? scored.first.rule : rules.defaultRule;

    final hint = _pickHint(best, question);

    // 1-in-3 chance to append an encouragement
    if (_rng.nextInt(3) == 0) {
      final enc = rules.encouragements[
          _rng.nextInt(rules.encouragements.length)];
      return '$hint $enc';
    }
    return hint;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[''`]"), '') // apostrophes
        .split(RegExp(r'[\s,;:.!?()\[\]/\\]+'))
        .where((t) => t.length > 2)
        .toList();
  }

  bool _asksForDirectAnswer(List<String> tokens) {
    const directWords = {
      'réponse', 'solution', 'résultat', 'donne', 'dis',
      'montres', 'explique', 'réponds',
    };
    return tokens.any(directWords.contains);
  }

  int _score(
    List<String> tokens,
    List<String> ruleTags,
    List<String> stepKeywords,
  ) {
    int s = 0;
    for (final tag in ruleTags) {
      if (tokens.any((t) => t.contains(tag) || tag.contains(t))) {
        s += 2; // rule tag match
      }
    }
    for (final kw in stepKeywords) {
      if (tokens.any(
        (t) => t.contains(kw.toLowerCase()) ||
               kw.toLowerCase().contains(t),
      )) {
        s += 1; // step keyword context boost
      }
    }
    return s;
  }

  /// Picks a hint template deterministically based on question hash,
  /// so the same question always gets the same hint.
  String _pickHint(_AiRule rule, String question) {
    if (rule.hints.isEmpty) return '';
    final idx = question.hashCode.abs() % rule.hints.length;
    return rule.hints[idx];
  }
}

// ─── Internal JSON models ─────────────────────────────────────────────────────

class _AiRules {
  final List<_AiRule> rules;
  final _AiRule defaultRule;
  final String noDirectAnswerMessage;
  final List<String> encouragements;

  const _AiRules({
    required this.rules,
    required this.defaultRule,
    required this.noDirectAnswerMessage,
    required this.encouragements,
  });

  factory _AiRules.fromJson(Map<String, dynamic> j) {
    final allRules = (j['rules'] as List)
        .map((r) => _AiRule.fromJson(r as Map<String, dynamic>))
        .toList();
    final defaultRule = allRules.firstWhere(
      (r) => r.id == 'rule_default',
      orElse: () => _AiRule(
        id: 'rule_default',
        tags: [],
        hints: [
          "C'est une bonne question ! Essaie de reformuler avec tes propres mots.",
          "Qu'est-ce que tu sais déjà sur ce sujet ?",
          "Relis l'étape précédente pour trouver un indice.",
        ],
      ),
    );
    return _AiRules(
      rules: allRules.where((r) => r.id != 'rule_default').toList(),
      defaultRule: defaultRule,
      noDirectAnswerMessage:
          j['no_direct_answer_message'] as String? ??
              "Je ne peux pas te donner la réponse directement, mais je peux t'aider.",
      encouragements:
          List<String>.from(j['encouragement_messages'] as List? ?? []),
    );
  }
}

class _AiRule {
  final String id;
  final List<String> tags;
  final List<String> hints;

  const _AiRule({
    required this.id,
    required this.tags,
    required this.hints,
  });

  factory _AiRule.fromJson(Map<String, dynamic> j) => _AiRule(
        id:    j['id'] as String,
        tags:  List<String>.from(j['tags'] as List? ?? []),
        hints: List<String>.from(j['hint_templates'] as List? ?? []),
      );
}

class _ScoredRule {
  final _AiRule rule;
  final int score;
  const _ScoredRule(this.rule, this.score);
}
