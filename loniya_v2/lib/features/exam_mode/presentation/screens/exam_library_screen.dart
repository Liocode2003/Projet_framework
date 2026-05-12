import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _ExamPart {
  final String title;
  final List<_Exercise> exercises;
  const _ExamPart({required this.title, required this.exercises});

  factory _ExamPart.fromJson(Map<String, dynamic> j) => _ExamPart(
        title: j['title'] as String,
        exercises: (j['exercises'] as List)
            .map((e) => _Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class _Exercise {
  final int number, points;
  final String title, content;
  const _Exercise(
      {required this.number, required this.title,
       required this.content, required this.points});

  factory _Exercise.fromJson(Map<String, dynamic> j) => _Exercise(
        number: j['number'] as int,
        title: j['title'] as String,
        content: j['content'] as String,
        points: j['points'] as int,
      );
}

class _ExamSubject {
  final String id, examType, subject;
  final String? serie;
  final int year, durationHours, coefficient;
  final List<_ExamPart> parts;

  const _ExamSubject({
    required this.id, required this.examType, required this.subject,
    this.serie, required this.year, required this.durationHours,
    required this.coefficient, required this.parts,
  });

  factory _ExamSubject.fromJson(Map<String, dynamic> j) => _ExamSubject(
        id:           j['id'] as String,
        examType:     j['exam_type'] as String,
        subject:      j['subject'] as String,
        serie:        j['serie'] as String?,
        year:         j['year'] as int,
        durationHours: j['duration_hours'] as int,
        coefficient:  j['coefficient'] as int,
        parts:        (j['parts'] as List)
            .map((p) => _ExamPart.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _examSubjectsProvider = FutureProvider.autoDispose<List<_ExamSubject>>((ref) async {
  final raw = await rootBundle.loadString('assets/mock_data/bepc_bac_subjects.json');
  return (json.decode(raw) as List)
      .map((j) => _ExamSubject.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ExamLibraryScreen extends ConsumerStatefulWidget {
  const ExamLibraryScreen({super.key});

  @override
  ConsumerState<ExamLibraryScreen> createState() => _ExamLibraryScreenState();
}

class _ExamLibraryScreenState extends ConsumerState<ExamLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _filterSubject = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_examSubjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: const Color(0xFF4A1500),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _Hero(),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.xpGold,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 14),
              tabs: const [
                Tab(text: 'BEPC'),
                Tab(text: 'BAC'),
              ],
            ),
          ),
        ],
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) => TabBarView(
            controller: _tabs,
            children: [
              _SubjectList(
                items: items.where((i) => i.examType == 'BEPC').toList(),
                filterSubject: _filterSubject,
                onFilterChanged: (s) => setState(() => _filterSubject = s),
              ),
              _SubjectList(
                items: items.where((i) => i.examType == 'BAC').toList(),
                filterSubject: _filterSubject,
                onFilterChanged: (s) => setState(() => _filterSubject = s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF4A1500), Color(0xFFCC4400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bibliothèque',
                        style: TextStyle(color: Colors.white60, fontFamily: 'Nunito',
                            fontSize: 12)),
                    const Text('BEPC & BAC',
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito',
                            fontSize: 24, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const Text('📚', style: TextStyle(fontSize: 36)),
              ]),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subject list ──────────────────────────────────────────────────────────────

class _SubjectList extends StatelessWidget {
  final List<_ExamSubject> items;
  final String filterSubject;
  final ValueChanged<String> onFilterChanged;

  const _SubjectList({
    required this.items,
    required this.filterSubject,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = ['Toutes', ...{for (final i in items) i.subject}.toList()..sort()];
    final filtered = filterSubject == 'Toutes'
        ? items
        : items.where((i) => i.subject == filterSubject).toList();

    return Column(children: [
      // Subject filter chips
      SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = subjects[i];
            final active = s == filterSubject;
            return GestureDetector(
              onTap: () => onFilterChanged(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF4A1500) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? const Color(0xFFCC4400) : AppColors.outline),
                ),
                child: Text(s,
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.onSurfaceVariant,
                    )),
              ),
            );
          },
        ),
      ),

      // List
      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Text('Aucun sujet disponible.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.onSurfaceVariant)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _ExamCard(subject: filtered[i]),
              ),
      ),
    ]);
  }
}

// ── Exam card ─────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final _ExamSubject subject;
  const _ExamCard({required this.subject});

  static const _subjectIcons = {
    'Mathématiques': '📐',
    'Français': '📖',
    'Sciences de la Vie et de la Terre': '🌱',
    'Physique-Chimie': '⚗️',
    'Histoire-Géographie': '🌍',
    'Histoire': '🏛️',
    'Philosophie': '🧠',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _subjectIcons[subject.subject] ?? '📚';
    final serieLabel = subject.serie != null ? ' — Série ${subject.serie}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(subject.subject,
                        style: AppTextStyles.titleSmall),
                    Text('${subject.examType} ${subject.year}$serieLabel',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ]),
                ),
                _InfoChip(label: '${subject.durationHours}h', icon: Icons.timer_outlined),
                const SizedBox(width: 6),
                _InfoChip(label: 'Coef. ${subject.coefficient}',
                    icon: Icons.bar_chart_rounded),
              ]),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(children: [
                Text('${subject.parts.length} partie(s)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openWithSage(context),
                  icon: const Text('🌿', style: TextStyle(fontSize: 13)),
                  label: const Text('Corriger avec Le Sage',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sage,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamDetailSheet(subject: subject),
    );
  }

  void _openWithSage(BuildContext context) {
    // Build a context-rich prompt for Le Sage
    final parts = subject.parts
        .expand((p) => p.exercises.where((e) => e.points > 0))
        .take(3)
        .map((e) => '• ${e.title} : ${e.content.substring(0, e.content.length.clamp(0, 120))}...')
        .join('\n');

    final prompt =
        'Je veux corriger le sujet ${subject.examType} ${subject.year} de ${subject.subject}. '
        'Voici les premiers exercices :\n$parts\n\n'
        'Peux-tu m\'aider à comprendre et résoudre ces exercices étape par étape ?';

    context.push(RouteNames.aiTutor, extra: prompt);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption
          .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
    ]),
  );
}

// ── Exam detail bottom sheet ──────────────────────────────────────────────────

class _ExamDetailSheet extends StatelessWidget {
  final _ExamSubject subject;
  const _ExamDetailSheet({required this.subject});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject.subject,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 18,
                        fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                Text('${subject.examType} ${subject.year}'
                    '${subject.serie != null ? " — Série ${subject.serie}" : ""}',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        color: AppColors.onSurfaceVariant)),
              ])),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // nav handled in _ExamCard._openWithSage
                },
                icon: const Text('🌿', style: TextStyle(fontSize: 13)),
                label: const Text('Le Sage',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                        fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ),
          const Divider(height: 24),
          // Content
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              itemCount: subject.parts.length,
              itemBuilder: (_, i) => _PartSection(part: subject.parts[i]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PartSection extends StatelessWidget {
  final _ExamPart part;
  const _PartSection({required this.part});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (part.title.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A1500).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(part.title,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A1500))),
        ),
      ...part.exercises.where((e) => e.points > 0).map((e) => _ExerciseCard(exercise: e)),
      const SizedBox(height: 8),
    ]);
  }
}

class _ExerciseCard extends StatelessWidget {
  final _Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(exercise.title,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.onSurface))),
          if (exercise.points > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.xpGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${exercise.points} pts',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.xpGold)),
            ),
        ]),
        const SizedBox(height: 8),
        Text(exercise.content,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.onSurface, height: 1.5)),
      ]),
    );
  }
}
