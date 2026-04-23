import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/homework_model.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    return role == 'teacher' ? const _TeacherHomeworkView() : const _StudentHomeworkView();
  }
}

// ── Student view ──────────────────────────────────────────────────────────────

class _StudentHomeworkView extends ConsumerWidget {
  const _StudentHomeworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder list — à brancher sur le provider Hive réel
    final homework = <HomeworkModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes devoirs',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: homework.isEmpty
          ? _EmptyState(
              icon: '📝',
              title: 'Aucun devoir pour l\'instant',
              subtitle: 'Tes enseignants n\'ont pas encore publié de devoirs.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: homework.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HomeworkCard(hw: homework[i]),
            ),
    );
  }
}

// ── Teacher view ──────────────────────────────────────────────────────────────

class _TeacherHomeworkView extends ConsumerWidget {
  const _TeacherHomeworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Devoirs publiés',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau devoir',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
      ),
      body: _EmptyState(
        icon: '📋',
        title: 'Aucun devoir publié',
        subtitle: 'Appuie sur "Nouveau devoir" pour en créer un.',
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateHomeworkSheet(),
    );
  }
}

// ── Homework Card ─────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;
  const _HomeworkCard({required this.hw});

  @override
  Widget build(BuildContext context) {
    final isUrgent = hw.isUrgent;
    final isDone   = hw.isDone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.successLight
            : isUrgent
                ? AppColors.errorLight
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.success.withOpacity(0.3)
              : isUrgent
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.surfaceVariant,
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isDone ? Icons.check_circle_rounded : Icons.assignment_rounded,
            color: isDone ? AppColors.success : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hw.title, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
            const SizedBox(height: 2),
            Text(hw.subject, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(
                isUrgent ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                size: 13,
                color: isUrgent ? AppColors.error : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDeadline(hw.deadline),
                style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUrgent ? AppColors.error : AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Text('${hw.durationMin} min',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                      color: AppColors.onSurfaceVariant)),
            ]),
          ],
        )),
        if (isDone)
          Text('${hw.score ?? '–'}/20',
              style: const TextStyle(color: AppColors.success,
                  fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  String _formatDeadline(DateTime d) {
    final now  = DateTime.now();
    final diff = d.difference(now);
    if (diff.inHours < 1) return 'Dans ${diff.inMinutes} min !';
    if (diff.inHours < 24) return 'Dans ${diff.inHours}h';
    return '${d.day}/${d.month} à ${d.hour}h${d.minute.toString().padLeft(2,'0')}';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String icon, title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18,
                  fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  color: AppColors.onSurfaceVariant, height: 1.5)),
        ]),
      ),
    );
  }
}

// ── Create Homework Sheet ─────────────────────────────────────────────────────

class _CreateHomeworkSheet extends StatefulWidget {
  const _CreateHomeworkSheet();

  @override
  State<_CreateHomeworkSheet> createState() => _CreateHomeworkSheetState();
}

class _CreateHomeworkSheetState extends State<_CreateHomeworkSheet> {
  final _titleCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  int _duration = 30;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Nouveau devoir',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        const SizedBox(height: 20),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre du devoir',
            prefixIcon: Icon(Icons.title_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _subjectCtrl,
          decoration: const InputDecoration(
            labelText: 'Matière',
            prefixIcon: Icon(Icons.school_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.timer_outlined, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text('Durée : $_duration min',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  color: AppColors.onSurface)),
          const Spacer(),
          Slider(
            value: _duration.toDouble(),
            min: 10, max: 120, divisions: 11,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _duration = v.round()),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Publier',
                style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
