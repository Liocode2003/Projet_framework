import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

// ── Question bank (shared with sprint) ────────────────────────────────────────

class _Q {
  final String question, correct;
  final List<String> choices;
  const _Q(this.question, this.correct, this.choices);
}

const _qBank = [
  _Q('7 × 8 = ?', '56', ['42', '56', '64', '48']),
  _Q('Capitale du Burkina Faso ?', 'Ouagadougou', ['Bobo-Dioulasso', 'Ouagadougou', 'Koudougou', 'Banfora']),
  _Q('45 ÷ 9 = ?', '5', ['4', '5', '6', '7']),
  _Q('"School" en français ?', 'école', ['maison', 'école', 'jardin', 'marché']),
  _Q('Jours dans une semaine ?', '7', ['5', '6', '7', '8']),
  _Q('Formule chimique de l\'eau ?', 'H₂O', ['CO₂', 'H₂O', 'O₂', 'N₂']),
  _Q('15 + 27 = ?', '42', ['40', '41', '42', '43']),
  _Q('Continent du Burkina Faso ?', 'Afrique', ['Europe', 'Asie', 'Afrique', 'Amérique']),
  _Q('6 × 7 = ?', '42', ['35', '40', '42', '48']),
  _Q('Planète la plus proche du Soleil ?', 'Mercure', ['Vénus', 'Mercure', 'Mars', 'Terre']),
  _Q('18 ÷ 3 = ?', '6', ['4', '5', '6', '7']),
  _Q('Couleur du drapeau BF (bande du haut) ?', 'Rouge', ['Vert', 'Rouge', 'Jaune', 'Bleu']),
  _Q('Côtés d\'un hexagone ?', '6', ['4', '5', '6', '8']),
  _Q('"Water" en français ?', 'Eau', ['Feu', 'Eau', 'Air', 'Terre']),
  _Q('9 × 9 = ?', '81', ['72', '81', '90', '99']),
  _Q('Indépendance de la Haute-Volta ?', '1960', ['1947', '1958', '1960', '1965']),
  _Q('Symbole chimique du fer ?', 'Fe', ['Fr', 'Fe', 'Fo', 'Fn']),
  _Q('12² = ?', '144', ['120', '134', '144', '148']),
  _Q('Fleuve qui traverse Ouagadougou ?', 'Nakambé', ['Niger', 'Volta', 'Nakambé', 'Mouhoun']),
  _Q('2³ = ?', '8', ['6', '8', '9', '12']),
];

List<_Q> _buildQuestions(int seed) {
  final list = List<_Q>.from(_qBank);
  list.shuffle(Random(seed));
  return list.take(10).toList();
}

// ── Duel code helpers ─────────────────────────────────────────────────────────

String _encodeCode(int seed, int score) =>
    'DUEL-${seed.toString().padLeft(4, '0')}-${score.toString().padLeft(4, '0')}';

({int seed, int score})? _decodeCode(String raw) {
  final parts = raw.trim().toUpperCase().split('-');
  if (parts.length != 3 || parts[0] != 'DUEL') return null;
  final seed = int.tryParse(parts[1]);
  final score = int.tryParse(parts[2]);
  if (seed == null || score == null) return null;
  return (seed: seed, score: score);
}

// ── Screen state machine ──────────────────────────────────────────────────────

enum _Phase { home, playing, result, joining, playingJoined, joinedResult }

class GameDuelScreen extends ConsumerStatefulWidget {
  const GameDuelScreen({super.key});

  @override
  ConsumerState<GameDuelScreen> createState() => _GameDuelScreenState();
}

class _GameDuelScreenState extends ConsumerState<GameDuelScreen> {
  _Phase _phase = _Phase.home;

  // Create-duel state
  late int _seed;
  late List<_Q> _questions;
  int _qIndex = 0;
  int _score = 0;
  int _timeLeft = 15;
  Timer? _timer;

  // Join-duel state
  final _codeCtrl = TextEditingController();
  int _challengerScore = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Create flow ──────────────────────────────────────────────────────────────

  void _startCreate() {
    _seed = Random().nextInt(9000) + 1000;
    _questions = _buildQuestions(_seed);
    _qIndex = 0;
    _score = 0;
    setState(() => _phase = _Phase.playing);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeLeft <= 1) {
        _nextQuestion(skipped: true);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _answer(String choice) {
    _timer?.cancel();
    if (choice == _questions[_qIndex].correct) _score += 100;
    _nextQuestion();
  }

  void _nextQuestion({bool skipped = false}) {
    if (_qIndex + 1 >= _questions.length) {
      _timer?.cancel();
      // Award XP for playing duel
      ref.read(gamificationNotifierProvider.notifier).refresh();
      setState(() => _phase = _Phase.result);
    } else {
      setState(() => _qIndex++);
      _startTimer();
    }
  }

  // ── Join flow ────────────────────────────────────────────────────────────────

  void _submitCode() {
    final decoded = _decodeCode(_codeCtrl.text);
    if (decoded == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code invalide. Format : DUEL-XXXX-XXXX')),
      );
      return;
    }
    _seed = decoded.seed;
    _challengerScore = decoded.score;
    _questions = _buildQuestions(_seed);
    _qIndex = 0;
    _score = 0;
    setState(() => _phase = _Phase.playingJoined);
    _startTimer();
  }

  void _answerJoined(String choice) {
    _timer?.cancel();
    if (choice == _questions[_qIndex].correct) _score += 100;
    if (_qIndex + 1 >= _questions.length) {
      _timer?.cancel();
      ref.read(gamificationNotifierProvider.notifier).refresh();
      setState(() => _phase = _Phase.joinedResult);
    } else {
      setState(() => _qIndex++);
      _startTimer();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        title: const Text('Duel',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        leading: _phase == _Phase.home
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _timer?.cancel();
                  setState(() => _phase = _Phase.home);
                },
              ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.home         => _HomeView(onCreate: _startCreate, onJoin: () => setState(() => _phase = _Phase.joining)),
      _Phase.playing      => _PlayView(q: _questions[_qIndex], index: _qIndex, total: _questions.length, score: _score, timeLeft: _timeLeft, onAnswer: _answer),
      _Phase.result       => _ResultView(score: _score, seed: _seed, onReset: () => setState(() => _phase = _Phase.home)),
      _Phase.joining      => _JoinView(ctrl: _codeCtrl, onSubmit: _submitCode),
      _Phase.playingJoined => _PlayView(q: _questions[_qIndex], index: _qIndex, total: _questions.length, score: _score, timeLeft: _timeLeft, onAnswer: _answerJoined),
      _Phase.joinedResult => _CompareView(myScore: _score, challengerScore: _challengerScore, onReset: () => setState(() => _phase = _Phase.home)),
    };
  }
}

// ── Home view ─────────────────────────────────────────────────────────────────

class _HomeView extends ConsumerWidget {
  final VoidCallback onCreate, onJoin;
  const _HomeView({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (ref.watch(currentUserProvider)?.name ?? 'Joueur').split(' ').first;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('⚔️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('Défi un(e) autre élève, $name !',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('10 questions · 15 secondes par question',
            style: TextStyle(color: Colors.white54, fontFamily: 'Nunito', fontSize: 13)),
        const SizedBox(height: 36),
        _BigButton(
          label: 'Créer un défi',
          icon: Icons.add_circle_outline_rounded,
          color: AppColors.primary,
          onTap: onCreate,
        ),
        const SizedBox(height: 14),
        _BigButton(
          label: 'Rejoindre un défi',
          icon: Icons.qr_code_scanner_rounded,
          color: AppColors.accent,
          onTap: onJoin,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Column(children: [
            Text('Comment ça marche ?',
                style: TextStyle(color: Colors.white, fontFamily: 'Nunito',
                    fontSize: 14, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            _HowStep(n: '1', t: 'Joue tes 10 questions → obtiens ton score'),
            _HowStep(n: '2', t: 'Partage ton code défi à ton adversaire'),
            _HowStep(n: '3', t: 'Ton adversaire joue la même série'),
            _HowStep(n: '4', t: 'Le meilleur score gagne !'),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String n, t;
  const _HowStep({required this.n, required this.t});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Center(child: Text(n, style: const TextStyle(
            color: Colors.white, fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w800))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(t, style: const TextStyle(
          color: Colors.white70, fontFamily: 'Nunito', fontSize: 12))),
    ]),
  );
}

// ── Play view ─────────────────────────────────────────────────────────────────

class _PlayView extends StatelessWidget {
  final _Q q;
  final int index, total, score, timeLeft;
  final ValueChanged<String> onAnswer;
  const _PlayView({
    required this.q, required this.index, required this.total,
    required this.score, required this.timeLeft, required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final progress = timeLeft / 15.0;
    final timerColor = timeLeft > 8 ? AppColors.primary
        : timeLeft > 4 ? AppColors.warning
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(children: [
        // Progress bar + timer
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                color: timerColor,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$timeLeft s',
              style: TextStyle(color: timerColor, fontFamily: 'Nunito',
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Q ${index + 1} / $total',
              style: const TextStyle(color: Colors.white54, fontFamily: 'Nunito', fontSize: 12)),
          Text('Score : $score',
              style: const TextStyle(color: AppColors.xpGold, fontFamily: 'Nunito',
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(q.question,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 20, fontWeight: FontWeight.w800, height: 1.4)),
        ),
        const SizedBox(height: 24),
        ...q.choices.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onAnswer(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white12),
                ),
                elevation: 0,
              ),
              child: Text(c, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        )),
      ]),
    );
  }
}

// ── Result view (code to share) ───────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int score, seed;
  final VoidCallback onReset;
  const _ResultView({required this.score, required this.seed, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final code = _encodeCode(seed, score);
    final perfect = score == 1000;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(perfect ? '🏆' : score >= 700 ? '🎉' : score >= 400 ? '👍' : '💪',
            style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('$score / 1000 points',
            style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(perfect ? 'Parfait !' : score >= 700 ? 'Excellent !' : score >= 400 ? 'Bien joué !' : 'Continue de t\'entraîner !',
            style: const TextStyle(color: Colors.white70, fontFamily: 'Nunito', fontSize: 16)),
        const SizedBox(height: 36),
        const Text('Ton code défi :',
            style: TextStyle(color: Colors.white60, fontFamily: 'Nunito', fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copié !')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(code,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                      fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(width: 12),
              const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Partage ce code à ton adversaire !',
            style: TextStyle(color: Colors.white54, fontFamily: 'Nunito', fontSize: 13)),
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Retour', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
        ),
      ]),
    );
  }
}

// ── Join view (enter code) ────────────────────────────────────────────────────

class _JoinView extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  const _JoinView({required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎯', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 20),
        const Text('Entre le code défi',
            style: TextStyle(color: Colors.white, fontFamily: 'Nunito',
                fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Format : DUEL-XXXX-XXXX',
            style: TextStyle(color: Colors.white54, fontFamily: 'Nunito', fontSize: 13)),
        const SizedBox(height: 32),
        TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'DUEL-XXXX-XXXX',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Jouer le défi',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Compare view (joined result) ──────────────────────────────────────────────

class _CompareView extends StatelessWidget {
  final int myScore, challengerScore;
  final VoidCallback onReset;
  const _CompareView({required this.myScore, required this.challengerScore, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final iWon = myScore > challengerScore;
    final isDraw = myScore == challengerScore;
    final emoji = isDraw ? '🤝' : iWon ? '🏆' : '😤';
    final message = isDraw ? 'Égalité !' : iWon ? 'Tu as gagné !' : 'Tu as perdu... revanche ?';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(message,
            style: TextStyle(
                color: isDraw ? Colors.white : iWon ? AppColors.xpGold : Colors.redAccent,
                fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 36),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _ScoreBox(label: 'Ton score', score: myScore, highlight: iWon || isDraw),
          _ScoreBox(label: 'Adversaire', score: challengerScore, highlight: !iWon || isDraw),
        ]),
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Nouveau défi',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int score;
  final bool highlight;
  const _ScoreBox({required this.label, required this.score, required this.highlight});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: highlight ? AppColors.primary.withOpacity(0.15) : const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: highlight ? AppColors.primary.withOpacity(0.5) : Colors.white12),
    ),
    child: Column(children: [
      Text(label, style: const TextStyle(
          color: Colors.white60, fontFamily: 'Nunito', fontSize: 13)),
      const SizedBox(height: 4),
      Text('$score', style: TextStyle(
          color: highlight ? AppColors.xpGold : Colors.white,
          fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900)),
      const Text('/ 1000', style: TextStyle(
          color: Colors.white38, fontFamily: 'Nunito', fontSize: 11)),
    ]),
  );
}

// ── Shared big button ─────────────────────────────────────────────────────────

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label,
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 16)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
