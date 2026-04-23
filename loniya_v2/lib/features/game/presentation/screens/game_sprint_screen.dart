import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../credits/presentation/providers/credit_provider.dart';

// ── Game gem types ────────────────────────────────────────────────────────────

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

// ── Game Sprint Screen ────────────────────────────────────────────────────────

class GameSprintScreen extends ConsumerStatefulWidget {
  const GameSprintScreen({super.key});

  @override
  ConsumerState<GameSprintScreen> createState() => _GameSprintScreenState();
}

class _GameSprintScreenState extends ConsumerState<GameSprintScreen> {
  static const int _gridSize = 6;
  static const int _totalSeconds = 60;

  late List<List<_GemType>> _grid;
  int _score      = 0;
  int _timeLeft   = _totalSeconds;
  int _selected   = -1;
  bool _started   = false;
  bool _finished  = false;
  Timer? _timer;

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
      _started   = true;
      _finished  = false;
      _score     = 0;
      _timeLeft  = _totalSeconds;
      _selected  = -1;
      _initGrid();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _endGame();
      }
    });
  }

  void _endGame() {
    setState(() => _finished = true);
    final creditsEarned = (_score ~/ 50).clamp(0, AppConstants.creditBonusCap);
    if (creditsEarned > 0) {
      ref.read(creditNotifierProvider.notifier).addBonus(creditsEarned);
    }
  }

  void _onGemTap(int index) {
    if (!_started || _finished) return;
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
      _swap(selRow, selCol, row, col);
    }
    setState(() => _selected = -1);
  }

  void _swap(int r1, int c1, int r2, int c2) {
    final tmp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = tmp;
    final matches = _findMatches();
    if (matches.isNotEmpty) {
      _clearMatches(matches);
    } else {
      // Undo swap if no matches
      _grid[r2][c2] = _grid[r1][c1];
      _grid[r1][c1] = tmp;
    }
    setState(() {});
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
    for (final idx in matches) {
      final r = idx ~/ _gridSize;
      final c = idx % _gridSize;
      for (int row = r; row > 0; row--) {
        _grid[row][c] = _grid[row-1][c];
      }
      _grid[0][c] = _GemType.values[_rng.nextInt(_GemType.values.length)];
    }
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
          // Score
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('$_score pts',
                style: const TextStyle(color: AppColors.gold,
                    fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900)),
          ),

          // Grid
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
                      final isSelected = _selected == i;
                      return GestureDetector(
                        onTap: () => _onGemTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : _gemColors[gem]!.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
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

          // Start / result overlay
          if (!_started || _finished)
            _GameOverlay(
              started: _started,
              finished: _finished,
              score: _score,
              onStart: _startGame,
              onBack: () => Navigator.pop(context),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

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
                      fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900)),
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
                      style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                )),
              ]),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('💎 Sprint 60s', style: TextStyle(
                  color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Aligne 3 gemmes ou plus en 60 secondes !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60,
                      fontFamily: 'Nunito', fontSize: 13)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
