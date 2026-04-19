import 'package:uuid/uuid.dart';
import '../models/orientation_result_model.dart';

/// Subjects and their coefficients per exam type (Burkina Faso curriculum).
class OrientationEngine {
  static const _uuid = Uuid();

  // ─── Subject definitions ───────────────────────────────────────────────────

  static const bepcSubjects = <String, int>{
    'Mathématiques':       5,
    'Français':            4,
    'Sciences':            2,
    'Histoire-Géographie': 2,
    'Physique-Chimie':     2,
    'Anglais':             2,
    'EPS':                 1,
  };

  static const bacSubjects = <String, int>{
    'Mathématiques':       4,
    'Physique-Chimie':     4,
    'Sciences':            3,
    'Français':            3,
    'Philosophie':         3,
    'Anglais':             2,
    'Histoire-Géographie': 2,
    'EPS':                 1,
  };

  Map<String, int> subjectsFor(String examType) =>
      examType == 'BAC' ? bacSubjects : bepcSubjects;

  // ─── Analysis ─────────────────────────────────────────────────────────────

  OrientationResultModel analyze({
    required String userId,
    required String examType,
    required Map<String, double> scores,
  }) {
    final coeffs   = subjectsFor(examType);
    final weighted = _weightedAverage(scores, coeffs);
    final filiere  = _recommendFiliere(scores, examType);
    final alts     = _alternatives(filiere, examType);
    final prob     = _successProbability(weighted);
    final text     = _analysisText(
      examType:   examType,
      average:    weighted,
      filiere:    filiere,
      probability: prob,
      scores:     scores,
    );

    return OrientationResultModel(
      id:                   _uuid.v4(),
      userId:               userId,
      examType:             examType,
      scores:               scores,
      recommendedFiliere:   filiere,
      alternativeFilières:  alts,
      successProbability:   prob,
      analysisText:         text,
      createdAt:            DateTime.now().toIso8601String(),
    );
  }

  // ─── Weighted average ─────────────────────────────────────────────────────

  double _weightedAverage(
    Map<String, double> scores,
    Map<String, int> coeffs,
  ) {
    double sum = 0;
    int totalCoeff = 0;
    for (final entry in scores.entries) {
      final c = coeffs[entry.key] ?? 1;
      sum += entry.value * c;
      totalCoeff += c;
    }
    return totalCoeff == 0 ? 0 : sum / totalCoeff;
  }

  // ─── Filière recommendation ────────────────────────────────────────────────

  String _recommendFiliere(Map<String, double> s, String examType) {
    final maths   = s['Mathématiques']       ?? 0;
    final science = s['Sciences']            ?? 0;
    final french  = s['Français']            ?? 0;
    final histo   = s['Histoire-Géographie'] ?? 0;
    final phys    = s['Physique-Chimie']     ?? 0;
    final philo   = s['Philosophie']         ?? 0;

    if (examType == 'BEPC') {
      final sciCluster = (maths + science + phys) / 3;
      final litCluster = (french + histo) / 2;

      if (sciCluster >= 14 && maths >= 14) return 'Série Scientifique (C/D)';
      if (sciCluster >= 12)                return 'Série Technique (F/G)';
      if (litCluster >= 12)                return 'Série Littéraire (A/B)';
      return 'Série Générale';
    } else {
      final serieC = (maths * 2 + phys) / 3;
      final serieD = (maths + science * 2) / 3;
      final serieA = (french + philo) / 2;

      final ranked = [
        _Score('Terminale C — Maths-Physique',    serieC),
        _Score('Terminale D — Maths-Sciences',    serieD),
        _Score('Terminale A — Lettres-Philo',     serieA),
      ]..sort((a, b) => b.v.compareTo(a.v));
      return ranked.first.name;
    }
  }

  List<String> _alternatives(String recommended, String examType) {
    const bepc = [
      'Série Scientifique (C/D)', 'Série Littéraire (A/B)',
      'Série Technique (F/G)', 'Série Générale',
    ];
    const bac = [
      'Terminale C — Maths-Physique', 'Terminale D — Maths-Sciences',
      'Terminale A — Lettres-Philo',
    ];
    final pool = examType == 'BAC' ? bac : bepc;
    return pool.where((f) => f != recommended).toList();
  }

  // ─── Success probability ───────────────────────────────────────────────────

  double _successProbability(double weightedAvg) {
    if (weightedAvg >= 16) return 0.92;
    if (weightedAvg >= 14) return 0.78;
    if (weightedAvg >= 12) return 0.62;
    if (weightedAvg >= 10) return 0.45;
    if (weightedAvg >= 8)  return 0.28;
    return 0.12;
  }

  // ─── Analysis text ─────────────────────────────────────────────────────────

  String _analysisText({
    required String examType,
    required double average,
    required String filiere,
    required double probability,
    required Map<String, double> scores,
  }) {
    final avgStr   = average.toStringAsFixed(1);
    final pctStr   = '${(probability * 100).toInt()}%';
    final weakSubs = _weakSubjects(scores);
    final strongSubs = _strongSubjects(scores);

    final buf = StringBuffer();

    buf.writeln(
      'Avec une moyenne pondérée de **$avgStr/20** à l\'$examType, '
      'le moteur d\'orientation recommande la filière **$filiere**.',
    );
    buf.writeln();

    buf.writeln(
      'Probabilité de réussite estimée : **$pctStr**. '
      '${_probabilityAdvice(probability)}',
    );
    buf.writeln();

    if (strongSubs.isNotEmpty) {
      buf.writeln(
        '✅ Points forts : ${strongSubs.join(', ')}. '
        'Continue à exploiter ces atouts.',
      );
    }
    if (weakSubs.isNotEmpty) {
      buf.writeln(
        '⚠️ Points à améliorer : ${weakSubs.join(', ')}. '
        'Ces matières nécessitent un travail renforcé avant l\'examen.',
      );
    }

    return buf.toString().trim();
  }

  List<String> _weakSubjects(Map<String, double> scores) =>
      scores.entries.where((e) => e.value < 10).map((e) => e.key).toList();

  List<String> _strongSubjects(Map<String, double> scores) =>
      scores.entries.where((e) => e.value >= 14).map((e) => e.key).toList();

  String _probabilityAdvice(double p) {
    if (p >= 0.78) return 'Excellent niveau — maintiens cet effort !';
    if (p >= 0.62) return 'Bon niveau — quelques révisions suffiront.';
    if (p >= 0.45) return 'Niveau passable — des révisions ciblées sont nécessaires.';
    return 'Niveau insuffisant — un travail intensif s\'impose avant l\'examen.';
  }
}

class _Score {
  final String name;
  final double v;
  const _Score(this.name, this.v);
}
