import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/gamification_model.dart';

class XpLevelCard extends StatelessWidget {
  final GamificationModel g;
  const XpLevelCard({super.key, required this.g});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.levelPurple, Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.levelPurple.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge + XP total
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  '${g.level}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Niveau ${g.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    '${g.totalXp} XP au total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Lessons count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${g.lessonsCompleted}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  'leçons',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          // XP progress bar
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: g.levelProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: AppColors.xpGold,
                  minHeight: 10,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${g.xpInCurrentLevel} / ${g.xpToNextLevel} XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              if (g.level < 100)
                Text(
                  'Niv. ${g.level + 1} → ${g.xpToNextLevel - g.xpInCurrentLevel} XP',
                  style: TextStyle(
                    color: AppColors.xpGold.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const Text(
                  'Niveau MAX',
                  style: TextStyle(color: AppColors.xpGold, fontSize: 12),
                ),
            ],
          ),

          // Subject XP chips
          if (g.xpBySubject.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: g.xpBySubject.entries
                  .where((e) => e.value > 0)
                  .map((e) => _SubjectChip(e.key, e.value))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String subject;
  final int xp;
  const _SubjectChip(this.subject, this.xp);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        '${subject.length > 4 ? subject.substring(0, 4) : subject}. $xp XP',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ));
  }
}
