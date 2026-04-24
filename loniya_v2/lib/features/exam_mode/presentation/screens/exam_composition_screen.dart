import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ── Question model ─────────────────────────────────────────────────────────────

class _Q {
  final String question, correct;
  final List<String> choices;
  final String? hint;
  const _Q(this.question, this.correct, this.choices, {this.hint});
}

// ── Question banks per subject ─────────────────────────────────────────────────

const _maths = [
  _Q('Quelle est la valeur de 15% de 200 ?', '30', ['20', '25', '30', '35']),
  _Q('Aire d\'un carré de côté 7 cm ?', '49 cm²', ['42 cm²', '49 cm²', '56 cm²', '14 cm²']),
  _Q('Si x + 5 = 12, alors x = ?', '7', ['5', '6', '7', '8']),
  _Q('2³ = ?', '8', ['4', '6', '8', '16']),
  _Q('Quel est le PGCD de 12 et 18 ?', '6', ['2', '3', '6', '9']),
  _Q('√49 = ?', '7', ['5', '6', '7', '8']),
  _Q('0,5 × 0,4 = ?', '0,2', ['0,02', '0,2', '2', '0,8']),
  _Q('Périmètre d\'un rectangle 6×4 ?', '20', ['10', '20', '24', '48']),
  _Q('3/4 + 1/2 = ?', '5/4', ['1', '4/6', '5/4', '7/4']),
  _Q('Si a = 3, b = 4, alors a² + b² = ?', '25', ['7', '14', '25', '49']),
];

const _physique = [
  _Q('Formule chimique du dioxyde de carbone ?', 'CO₂', ['C₂O', 'CO₂', 'CO', 'C₂O₃']),
  _Q('Vitesse approximative de la lumière ?', '300 000 km/s', ['3 000 km/s', '30 000 km/s', '300 000 km/s', '3 000 000 km/s']),
  _Q('Formule de la densité ?', 'd = m/V', ['d = V/m', 'd = m×V', 'd = m/V', 'd = m²/V']),
  _Q('Unité SI de la force ?', 'Newton (N)', ['Joule', 'Watt', 'Newton (N)', 'Pascal']),
  _Q('L\'eau bout à quelle température (pression normale) ?', '100 °C', ['90 °C', '95 °C', '100 °C', '110 °C']),
  _Q('Formule de l\'eau ?', 'H₂O', ['H₂O₂', 'HO', 'H₂O', 'H₃O']),
  _Q('Symbole chimique du sodium ?', 'Na', ['So', 'Na', 'Sd', 'Sn']),
  _Q('Un atome est composé d\'un noyau et de ?', 'Électrons', ['Protons', 'Neutrons', 'Électrons', 'Photons']),
  _Q('Énergie = Puissance × ?', 'Temps', ['Masse', 'Vitesse', 'Temps', 'Volume']),
  _Q('Masse volumique de l\'eau (kg/m³) ?', '1 000', ['100', '1 000', '10 000', '500']),
];

const _francais = [
  _Q('Pluriel de "bal" ?', 'bals', ['baux', 'bals', 'bales', 'bal']),
  _Q('"Il court comme un lapin" est une ?', 'Comparaison', ['Métaphore', 'Comparaison', 'Hyperbole', 'Ellipse']),
  _Q('Quel est le synonyme de "perspicace" ?', 'Clairvoyant', ['Stupide', 'Clairvoyant', 'Lent', 'Timide']),
  _Q('Conjuguez "avoir" au passé composé (je) ?', 'J\'ai eu', ['J\'avais', 'J\'ai eu', 'J\'eus', 'J\'aurai']),
  _Q('Féminin de "acteur" ?', 'actrice', ['acteuse', 'acteure', 'actrice', 'actrisse']),
  _Q('Quel temps est "Il aurait mangé" ?', 'Conditionnel passé', ['Futur antérieur', 'Conditionnel passé', 'Subjonctif passé', 'Plus-que-parfait']),
  _Q('Un adverbe modifie ?', 'Un verbe, adjectif ou adverbe', ['Un nom', 'Un verbe, adjectif ou adverbe', 'Un pronom', 'Un article']),
  _Q('Quelle est la nature de "rapidement" ?', 'Adverbe', ['Adjectif', 'Nom', 'Adverbe', 'Verbe']),
  _Q('Antonyme de "austère" ?', 'Exubérant', ['Sévère', 'Strict', 'Exubérant', 'Sobre']),
  _Q('Titre d\'une œuvre de Victor Hugo ?', 'Les Misérables', ['Candide', 'Les Misérables', 'Germinal', 'L\'Assommoir']),
];

const _histgeo = [
  _Q('En quelle année le Burkina Faso a obtenu son indépendance ?', '1960', ['1958', '1960', '1962', '1966']),
  _Q('Quelle est la monnaie de l\'UEMOA ?', 'Franc CFA', ['Cedi', 'Naira', 'Franc CFA', 'Dalasi']),
  _Q('Quel fleuve traverse Ouagadougou ?', 'Nakambé (Volta Blanche)', ['Niger', 'Nakambé (Volta Blanche)', 'Mouhoun', 'Comoé']),
  _Q('En quel siècle a eu lieu la Révolution française ?', 'XVIIIe siècle', ['XVIe siècle', 'XVIIe siècle', 'XVIIIe siècle', 'XIXe siècle']),
  _Q('Quel continent est l\'Afrique de l\'Ouest ?', 'Afrique', ['Asie', 'Afrique', 'Amérique', 'Europe']),
  _Q('Capitale de la Côte d\'Ivoire (officielle) ?', 'Yamoussoukro', ['Abidjan', 'Yamoussoukro', 'Bouaké', 'Korhogo']),
  _Q('Quel événement mondial a eu lieu en 1945 ?', 'Fin de la 2e Guerre mondiale', ['1re Guerre mondiale', 'Révolution russe', 'Fin de la 2e Guerre mondiale', 'Débarquement de Normandie']),
  _Q('Le Sahara est situé en ?', 'Afrique du Nord', ['Afrique centrale', 'Afrique du Sud', 'Afrique du Nord', 'Afrique de l\'Est']),
  _Q('Première civilisation de l\'écriture ?', 'Sumériens (Mésopotamie)', ['Égyptiens', 'Grecs', 'Sumériens (Mésopotamie)', 'Romains']),
  _Q('L\'ONU a été créée en ?', '1945', ['1919', '1939', '1945', '1948']),
];

const _banks = {
  'Mathématiques': _maths,
  'Physique-Chimie': _physique,
  'Français': _francais,
  'Histoire-Géographie': _histgeo,
};

// ── Exam Composition Screen ────────────────────────────────────────────────────

class ExamCompositionScreen extends ConsumerStatefulWidget {
  final String subject;
  const ExamCompositionScreen({super.key, required this.subject});

  @override
  ConsumerState<ExamCompositionScreen> createState() =>
      _ExamCompositionScreenState();
}

class _ExamCompositionScreenState
    extends ConsumerState<ExamCompositionScreen> {
  late List<_Q> _questions;
  final List<String?> _answers = [];
  int _current = 0;
  bool _done = false;
  int _elapsedSec = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questions = List.from(_banks[widget.subject] ?? _maths)..shuffle();
    _answers.addAll(List<String?>.filled(_questions.length, null));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_done) setState(() => _elapsedSec++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(String choice) {
    if (_done) return;
    setState(() => _answers[_current] = choice);
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_current > 0) setState(() => _current--);
  }

  void _submit() {
    _timer?.cancel();
    final correct = _questions
        .asMap()
        .entries
        .where((e) => _answers[e.key] == e.value.correct)
        .length;
    final score = ((correct / _questions.length) * 20).round();

    // Save result to Hive exams box
    final userId = ref.read(authNotifierProvider).userId ?? '';
    Hive.box(HiveBoxes.exams).put(
      '${const Uuid().v4()}',
      {
        'userId': userId,
        'subject': widget.subject,
        'score': score,
        'total': 20,
        'correct': correct,
        'questions': _questions.length,
        'durationSec': _elapsedSec,
        'date': DateTime.now().toIso8601String(),
      },
    );

    setState(() => _done = true);
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _done,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmQuit(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.subject,
              style: const TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: _done
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            if (!_done)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _TimerBadge(elapsed: _formatTime(_elapsedSec)),
              ),
          ],
        ),
        body: _done ? _ResultView(
          subject: widget.subject,
          answers: _answers,
          questions: _questions,
          elapsedSec: _elapsedSec,
          onRetry: () => Navigator.pop(context),
        ) : _QuizView(
          questions: _questions,
          answers: _answers,
          current: _current,
          onPick: _pick,
          onNext: _next,
          onPrev: _prev,
          onSubmit: _submit,
        ),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quitter l\'examen ?',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text(
            'Ta progression sera perdue. Souhaites-tu vraiment quitter ?',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continuer',
                  style: TextStyle(fontFamily: 'Nunito'))),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Quitter',
                style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }
}

// ── Quiz View ──────────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  final List<_Q> questions;
  final List<String?> answers;
  final int current;
  final void Function(String) onPick;
  final VoidCallback onNext, onPrev, onSubmit;

  const _QuizView({
    required this.questions,
    required this.answers,
    required this.current,
    required this.onPick,
    required this.onNext,
    required this.onPrev,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final q = questions[current];
    final answered = answers[current];
    final isLast = current == questions.length - 1;

    return Column(children: [
      // Progress bar
      LinearProgressIndicator(
        value: (current + 1) / questions.length,
        backgroundColor: AppColors.surfaceVariant,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        minHeight: 4,
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question ${current + 1} / ${questions.length}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(q.question,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        height: 1.5)),
              ),
              const SizedBox(height: 20),
              ...q.choices.map((c) {
                final selected = answered == c;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onPick(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.outline,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey400,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.onSurface)),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),

      // Navigation buttons
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Row(children: [
          if (current > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Précédent',
                    style: TextStyle(
                        fontFamily: 'Nunito', color: AppColors.onSurface)),
              ),
            ),
          if (current > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: answered != null
                  ? (isLast ? onSubmit : onNext)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: isLast ? AppColors.accent : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isLast ? 'Terminer l\'examen' : 'Suivant',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Result View ────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final String subject;
  final List<String?> answers;
  final List<_Q> questions;
  final int elapsedSec;
  final VoidCallback onRetry;

  const _ResultView({
    required this.subject,
    required this.answers,
    required this.questions,
    required this.elapsedSec,
    required this.onRetry,
  });

  int get _correct =>
      questions.asMap().entries.where((e) => answers[e.key] == e.value.correct).length;

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final correct = _correct;
    final score = ((correct / total) * 20).round();
    final pct = (correct / total * 100).round();
    final mins = elapsedSec ~/ 60;
    final secs = elapsedSec % 60;

    Color scoreColor;
    String mention;
    if (score >= 16) { scoreColor = AppColors.success; mention = 'Excellent ! 🎉'; }
    else if (score >= 12) { scoreColor = AppColors.primary; mention = 'Bien ! 👍'; }
    else if (score >= 10) { scoreColor = AppColors.warning; mention = 'Passable 😐'; }
    else { scoreColor = AppColors.error; mention = 'À retravailler 📚'; }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scoreColor.withOpacity(0.8), scoreColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(mention,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('$score / 20',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: 52,
                    fontWeight: FontWeight.w900)),
            Text('$correct / $total bonnes réponses ($pct%)',
                style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                    fontSize: 13)),
            const SizedBox(height: 8),
            Text('⏱ $mins min ${secs}s',
                style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                    fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 24),

        // Corrections
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Corrections',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface)),
        ),
        const SizedBox(height: 12),

        ...questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          final given = answers[i];
          final ok = given == q.correct;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ok ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: ok
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: ok ? AppColors.success : AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(q.question,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                ),
              ]),
              if (!ok) ...[
                const SizedBox(height: 6),
                Text('Ta réponse : ${given ?? "—"}',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.error)),
              ],
              const SizedBox(height: 4),
              Text('Bonne réponse : ${q.correct}',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ok ? AppColors.success : AppColors.onSurface)),
            ]),
          );
        }),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour aux examens',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ── Timer Badge ────────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  final String elapsed;
  const _TimerBadge({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 14),
        const SizedBox(width: 4),
        Text(elapsed,
            style: const TextStyle(
                color: AppColors.primary,
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
