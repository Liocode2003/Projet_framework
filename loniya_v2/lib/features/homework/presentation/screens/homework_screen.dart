import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/homework_model.dart';
import '../providers/homework_provider.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    return role == 'teacher'
        ? const _TeacherHomeworkView()
        : const _StudentHomeworkView();
  }
}

// ── Student view ──────────────────────────────────────────────────────────────

class _StudentHomeworkView extends ConsumerWidget {
  const _StudentHomeworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkNotifierProvider);
    final pending  = homework.where((h) => !h.isDone).toList();
    final done     = homework.where((h) => h.isDone).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes devoirs',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (homework.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _StatsChip(
                  done: done.length, total: homework.length),
            ),
        ],
      ),
      body: homework.isEmpty
          ? const _EmptyState(
              icon: '📝',
              title: 'Aucun devoir pour l\'instant',
              subtitle:
                  'Tes enseignants n\'ont pas encore publié de devoirs.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader('À faire (${pending.length})'),
                  ...pending.map((hw) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HomeworkCard(
                          hw: hw,
                          onMarkDone: () =>
                              _showDoneDialog(context, ref, hw),
                        ),
                      )),
                ],
                if (done.isNotEmpty) ...[
                  _SectionHeader('Terminés (${done.length})'),
                  ...done.map((hw) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HomeworkCard(hw: hw),
                      )),
                ],
              ],
            ),
    );
  }

  void _showDoneDialog(
      BuildContext context, WidgetRef ref, HomeworkModel hw) {
    final scoreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Marquer comme fait',
            style: const TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${hw.title}',
              style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: scoreCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Note obtenue (sur 20)',
              prefixIcon: Icon(Icons.grade_rounded),
              hintText: 'ex : 15',
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () {
              final score = int.tryParse(scoreCtrl.text.trim()) ?? 0;
              ref
                  .read(homeworkNotifierProvider.notifier)
                  .markDone(hw.id, score: score.clamp(0, 20));
              Navigator.pop(ctx);
            },
            child: const Text('Confirmer',
                style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }
}

// ── Teacher view ──────────────────────────────────────────────────────────────

class _TeacherHomeworkView extends ConsumerWidget {
  const _TeacherHomeworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Devoirs publiés',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau devoir',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
      ),
      body: homework.isEmpty
          ? const _EmptyState(
              icon: '📋',
              title: 'Aucun devoir publié',
              subtitle: 'Appuie sur "Nouveau devoir" pour en créer un.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: homework.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _TeacherCard(
                hw: homework[i],
                onDelete: () => ref
                    .read(homeworkNotifierProvider.notifier)
                    .delete(homework[i].id),
              ),
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateHomeworkSheet(
        onCreate: (title, subject, duration, deadline) {
          ref.read(homeworkNotifierProvider.notifier).create(
                title: title,
                subject: subject,
                durationMin: duration,
                deadline: deadline,
              );
        },
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;
  final VoidCallback? onMarkDone;
  const _HomeworkCard({required this.hw, this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final isUrgent = hw.isUrgent;
    final isDone = hw.isDone;

    return GestureDetector(
      onTap: isDone ? null : onMarkDone,
      child: Container(
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
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.assignment_rounded,
              color: isDone ? AppColors.success : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hw.title,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text(hw.subject,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                  isUrgent
                      ? Icons.warning_amber_rounded
                      : Icons.schedule_rounded,
                  size: 13,
                  color: isUrgent
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDeadline(hw.deadline),
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUrgent
                          ? AppColors.error
                          : AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
                Text('${hw.durationMin} min',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant)),
              ]),
            ],
          )),
          if (isDone)
            Column(children: [
              Text('${hw.score ?? 0}/20',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
              const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 16),
            ])
          else if (onMarkDone != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Fait',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
        ]),
      ),
    );
  }

  String _formatDeadline(String deadlineIso) {
    final d = DateTime.tryParse(deadlineIso);
    if (d == null) return '—';
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'En retard !';
    if (diff.inHours < 1) return 'Dans ${diff.inMinutes} min !';
    if (diff.inHours < 24) return 'Dans ${diff.inHours}h';
    return '${d.day}/${d.month} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }
}

class _TeacherCard extends StatelessWidget {
  final HomeworkModel hw;
  final VoidCallback onDelete;
  const _TeacherCard({required this.hw, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_outlined,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hw.title,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            const SizedBox(height: 2),
            Text('${hw.subject} · ${hw.durationMin} min',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant)),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5)),
    );
  }
}

// ── Stats chip ────────────────────────────────────────────────────────────────

class _StatsChip extends StatelessWidget {
  final int done, total;
  const _StatsChip({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$done/$total faits',
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.success)),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String icon, title, subtitle;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5)),
        ]),
      ),
    );
  }
}

// ── Create Homework Sheet ─────────────────────────────────────────────────────

class _CreateHomeworkSheet extends StatefulWidget {
  final void Function(
      String title, String subject, int duration, DateTime deadline) onCreate;
  const _CreateHomeworkSheet({required this.onCreate});

  @override
  State<_CreateHomeworkSheet> createState() => _CreateHomeworkSheetState();
}

class _CreateHomeworkSheetState extends State<_CreateHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  String _subject = AppConstants.subjects.first;
  int _duration = 30;
  DateTime _deadline = DateTime.now().add(const Duration(days: 2));

  @override
  void dispose() {
    _titleCtrl.dispose();
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
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Nouveau devoir',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface)),
        const SizedBox(height: 20),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre du devoir',
            prefixIcon: Icon(Icons.title_rounded),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _subject,
          decoration: const InputDecoration(
            labelText: 'Matière',
            prefixIcon: Icon(Icons.school_rounded),
          ),
          items: AppConstants.subjects
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _subject = v ?? _subject),
        ),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text('Durée : $_duration min',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.onSurface)),
          Expanded(
            child: Slider(
              value: _duration.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.event_rounded,
              color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Text(
            'Rendre pour : ${_deadline.day}/${_deadline.month}/${_deadline.year}',
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppColors.onSurface),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
            child: const Text('Changer',
                style: TextStyle(
                    fontFamily: 'Nunito', color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return;
              widget.onCreate(title, _subject, _duration, _deadline);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Publier',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
