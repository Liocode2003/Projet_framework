import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../credits/presentation/providers/credit_provider.dart';

// ── Gem types ─────────────────────────────────────────────────────────────────

enum _GemType { rouge, bleu, vert, or, violet }

const _gemEmoji = {
  _GemType.rouge:  '🔴',
  _GemType.bleu:   '🔵',
  _GemType.vert:   '🟢',
  _GemType.or:     '🟡',
  _GemType.violet: '🟣',
};

const _gemColors = {
  _GemType.rouge:  Color(0xFFD32F2F),
  _GemType.bleu:   Color(0xFF1565C0),
  _GemType.vert:   Color(0xFF2E7D32),
  _GemType.or:     Color(0xFFF9A825),
  _GemType.violet: Color(0xFF6A1B9A),
};

// ── Question bank ─────────────────────────────────────────────────────────────

class _Q {
  final String question, correct;
  final List<String> choices;
  const _Q(this.question, this.correct, this.choices);
}

const _qBank = [
  _Q('7 × 8 = ?',                        '56',           ['42', '56', '64', '48']),
  _Q('Capitale du Burkina Faso ?',        'Ouagadougou',  ['Bobo-Dioulasso', 'Ouagadougou', 'Koudougou', 'Banfora']),
  _Q('45 ÷ 9 = ?',                        '5',            ['4', '5', '6', '7']),
  _Q('"School" en français ?',            'école',        ['maison', 'école', 'jardin', 'marché']),
  _Q('Jours dans une semaine ?',          '7',            ['5', '6', '7', '8']),
  _Q('Formule chimique de l\'eau ?',      'H₂O',          ['CO₂', 'H₂O', 'O₂', 'N₂']),
  _Q('15 + 27 = ?',                       '42',           ['40', '41', '42', '43']),
  _Q('Continent du Burkina Faso ?',       'Afrique',      ['Europe', 'Asie', 'Afrique', 'Amérique']),
  _Q('6 × 7 = ?',                         '42',           ['35', '40', '42', '48']),
  _Q('Planète la plus proche du Soleil ?','Mercure',      ['Vénus', 'Mercure', 'Mars', 'Terre']),
  _Q('18 ÷ 3 = ?',                        '6',            ['4', '5', '6', '7']),
  _Q('Couleur du drapeau du BF (bande du haut) ?', 'Rouge', ['Vert', 'Rouge', 'Jaune', 'Bleu']),
  _Q('Combien de côtés a un hexagone ?',  '6',            ['4', '5', '6', '8']),
  _Q('"Water" en français ?',             'Eau',          ['Feu', 'Eau', 'Air', 'Terre']),
  _Q('9 × 9 = ?',                         '81',           ['72', '81', '90', '99']),
];

// ── Sprint Screen ─────────────────────────────────────────────────────────────

class GameSprintScreen extends ConsumerStatefulWidget {
  const GameSprintScreen({super.key});

  @override
  ConsumerState<GameSprintScreen> createState() => _GameSprintScreenState();
}

class _GameSprintScreenState extends ConsumerState<GameSprintScreen> {
  static const int _gridSize    = 6;
  static const int _totalSecs   = 60;

  late List<List<_GemType>> _grid;
  int  _score     = 0;
  int  _timeLeft  = _totalSecs;
  int  _selected  = -1;
  bool _started   = false;
  bool _finished  = false;
  bool _paused    = false;   // true while question overlay is shown
  Timer? _timer;

  // pending match data (waiting for question answer)
  Set<int>? _pendingMatches;
  int _swapR1 = 0, _swapC1 = 0, _swapR2 = 0, _swapC2 = 0;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initGrid() {
    _grid = List.generate(
      _gridSize,
      (_) => List.generate(
        _gridSize,
        (_) => _GemType.values[_rng.nextInt(_GemType.values.length)],
      ),
    );
  }

  void _startGame() {
    setState(() {
      _started  = true;
      _finished = false;
      _paused   = false;
      _score    = 0;
      _timeLeft = _totalSecs;
      _selected = -1;
      _pendingMatches = null;
      _initGrid();
    });
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_paused) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() { _finished = true; _paused = false; });
    // Flat +3 credits per sprint completed (spec requirement)
    ref.read(creditNotifierProvider.notifier)
        .addBonus(AppConstants.creditPerSprint);
  }

  void _onGemTap(int index) {
    if (!_started || _finished || _paused) return;
    final row = index ~/ _gridSize;
    final col = index % _gridSize;

    if (_selected == -1) {
      setState(() => _selected = index);
      return;
    }

    final selRow = _selected ~/ _gridSize;
    final selCol = _selected % _gridSize;
    final isAdjacent = (row == selRow && (col - selCol).abs() == 1) ||
        (col == selCol && (row - selRow).abs() == 1);

    if (isAdjacent) {
      _trySwap(selRow, selCol, row, col);
    }
    setState(() => _selected = -1);
  }

  void _trySwap(int r1, int c1, int r2, int c2) {
    final tmp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = tmp;

    final matches = _findMatches();
    if (matches.isNotEmpty) {
      // Pause timer and show a question
      _swapR1 = r1; _swapC1 = c1;
      _swapR2 = r2; _swapC2 = c2;
      _pendingMatches = matches;
      setState(() { _paused = true; });
      _showQuestion(matches);
    } else {
      // Undo — no matches
      _grid[r2][c2] = _grid[r1][c1];
      _grid[r1][c1] = tmp;
      setState(() {});
    }
  }

  void _showQuestion(Set<int> matches) {
    final q = _qBank[_rng.nextInt(_qBank.length)];
    final shuffled = [...q.choices]..shuffle(_rng);

    showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionSheet(question: q, shuffledChoices: shuffled),
    ).then((correct) {
      if (!mounted) return;
      if (correct == true) {
        _clearMatches(matches);
        setState(() { _paused = false; });
      } else {
        // Undo swap
        final tmp = _grid[_swapR1][_swapC1];
        _grid[_swapR1][_swapC1] = _grid[_swapR2][_swapC2];
        _grid[_swapR2][_swapC2] = tmp;
        setState(() { _paused = false; _pendingMatches = null; });
      }
    });
  }

  Set<int> _findMatches() {
    final toRemove = <int>{};
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize - 2; c++) {
        if (_grid[r][c] == _grid[r][c+1] && _grid[r][c] == _grid[r][c+2]) {
          toRemove.addAll([r*_gridSize+c, r*_gridSize+c+1, r*_gridSize+c+2]);
        }
      }
    }
    for (int c = 0; c < _gridSize; c++) {
      for (int r = 0; r < _gridSize - 2; r++) {
        if (_grid[r][c] == _grid[r+1][c] && _grid[r][c] == _grid[r+2][c]) {
          toRemove.addAll([r*_gridSize+c, (r+1)*_gridSize+c, (r+2)*_gridSize+c]);
        }
      }
    }
    return toRemove;
  }

  void _clearMatches(Set<int> matches) {
    _score += matches.length * 10;
    _pendingMatches = null;
    for (final idx in matches) {
      final r = idx ~/ _gridSize;
      final c = idx % _gridSize;
      for (int row = r; row > 0; row--) {
        _grid[row][c] = _grid[row-1][c];
      }
      _grid[0][c] = _GemType.values[_rng.nextInt(_GemType.values.length)];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        title: const Text('Sprint 60s',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        actions: [
          if (_started && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _TimerChip(timeLeft: _timeLeft),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text('$_score pts',
                  style: const TextStyle(color: AppColors.gold,
                      fontFamily: 'Nunito', fontSize: 32,
                      fontWeight: FontWeight.w900)),
              if (_paused)
                const Text('⏸ Question en cours…',
                    style: TextStyle(color: Colors.white54,
                        fontFamily: 'Nunito', fontSize: 12)),
            ]),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (_, i) {
                      final row = i ~/ _gridSize;
                      final col = i % _gridSize;
                      final gem = _grid[row][col];
                      final isSelected  = _selected == i;
                      final isPending   = _pendingMatches?.contains(i) ?? false;
                      return GestureDetector(
                        onTap: () => _onGemTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isPending
                                ? Colors.white.withOpacity(0.5)
                                : isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : _gemColors[gem]!.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected || isPending
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: _gemColors[gem]!.withOpacity(0.4),
                                blurRadius: 8, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(_gemEmoji[gem]!,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (!_started || _finished)
            _GameOverlay(
              started:  _started,
              finished: _finished,
              score:    _score,
              onStart:  _startGame,
              onBack:   () => Navigator.pop(context),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Question bottom sheet ──────────────────────────────────────────────────────

class _QuestionSheet extends StatefulWidget {
  final _Q question;
  final List<String> shuffledChoices;
  const _QuestionSheet({required this.question, required this.shuffledChoices});

  @override
  State<_QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends State<_QuestionSheet> {
  String? _chosen;
  bool _answered = false;

  void _pick(String choice) {
    if (_answered) return;
    setState(() { _chosen = choice; _answered = true; });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context, choice == widget.question.correct);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Text('🌿', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('Le Sage demande…',
                style: TextStyle(color: Colors.white54,
                    fontFamily: 'Nunito', fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Text(widget.question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white,
                  fontFamily: 'Nunito', fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          ...widget.shuffledChoices.map((c) {
            Color bg = Colors.white.withOpacity(0.08);
            if (_answered && _chosen == c) {
              bg = c == widget.question.correct
                  ? AppColors.success.withOpacity(0.25)
                  : AppColors.error.withOpacity(0.25);
            } else if (_answered && c == widget.question.correct) {
              bg = AppColors.success.withOpacity(0.25);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _pick(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(c,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,
                          fontFamily: 'Nunito', fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final int timeLeft;
  const _TimerChip({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final isUrgent = timeLeft <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error.withOpacity(0.2) : Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isUrgent ? AppColors.error : Colors.white24),
      ),
      child: Text('$timeLeft s',
          style: TextStyle(
              color: isUrgent ? AppColors.error : Colors.white,
              fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }
}

class _GameOverlay extends StatelessWidget {
  final bool started, finished;
  final int score;
  final VoidCallback onStart, onBack;

  const _GameOverlay({
    required this.started, required this.finished,
    required this.score, required this.onStart, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: finished
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏱️ Temps écoulé !', style: TextStyle(
                  color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Score final : $score pts',
                  style: const TextStyle(color: AppColors.gold,
                      fontFamily: 'Nunito', fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('+${AppConstants.creditPerSprint} crédits gagnés !',
                  style: const TextStyle(color: AppColors.sage,
                      fontFamily: 'Nunito', fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Quitter',
                      style: TextStyle(fontFamily: 'Nunito')),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Rejouer',
                      style: TextStyle(fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700)),
                )),
              ]),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚡ Sprint 60s', style: TextStyle(
                  color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Aligne 3 gemmes · réponds à la question · gagne des points !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60,
                    fontFamily: 'Nunito', fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text('+${AppConstants.creditPerSprint} crédits à la fin',
                  style: const TextStyle(color: AppColors.gold,
                      fontFamily: 'Nunito', fontSize: 12)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Jouer !',
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ]),
    );
  }
}
