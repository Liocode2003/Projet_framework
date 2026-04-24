import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class ExamModeScreen extends ConsumerStatefulWidget {
  const ExamModeScreen({super.key});

  @override
  ConsumerState<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends ConsumerState<ExamModeScreen> {
  int _tab = 0; // 0 = préparation, 1 = composition

  @override
  Widget build(BuildContext context) {
    final user  = ref.watch(currentUserProvider);
    final grade = user?.gradeLevel ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ExamHero(grade: grade),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _TabBar(selected: _tab,
                  onChanged: (i) => setState(() => _tab = i)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _tab == 0 ? _prepContent(context) : _compositionContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _prepContent(BuildContext context) => [
    const Text(
      'Prépare ton examen',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 20,
          fontWeight: FontWeight.w800, color: AppColors.onSurface),
    ),
    const SizedBox(height: 6),
    const Text(
      'Révise les matières clés avec Le Sage et des QCM chronométrés.',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.onSurfaceVariant, height: 1.5),
    ),
    const SizedBox(height: 24),

    ...AppConstants.subjects.take(6).map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SubjectPrepCard(subject: s),
    )),

    const SizedBox(height: 16),
    _InfoBanner(
      icon: '🌿',
      text: 'Le Sage peut générer des annales et corriger tes réponses.',
      color: AppColors.sage,
    ),
  ];

  List<Widget> _compositionContent(BuildContext context) => [
    const Text(
      'Mode Composition',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 20,
          fontWeight: FontWeight.w800, color: AppColors.onSurface),
    ),
    const SizedBox(height: 6),
    const Text(
      'Simule une vraie épreuve avec sujets générés par IA et correction automatique.',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.onSurfaceVariant, height: 1.5),
    ),
    const SizedBox(height: 24),

    _CompositionCard(
      icon: '📐',
      title: 'Mathématiques',
      duration: '3h',
      onStart: () => _startComposition(context, 'Mathématiques'),
    ),
    const SizedBox(height: 12),
    _CompositionCard(
      icon: '⚗️',
      title: 'Physique-Chimie',
      duration: '2h',
      onStart: () => _startComposition(context, 'Physique-Chimie'),
    ),
    const SizedBox(height: 12),
    _CompositionCard(
      icon: '📖',
      title: 'Français',
      duration: '3h',
      onStart: () => _startComposition(context, 'Français'),
    ),
    const SizedBox(height: 12),
    _CompositionCard(
      icon: '🌍',
      title: 'Histoire-Géographie',
      duration: '2h',
      onStart: () => _startComposition(context, 'Histoire-Géographie'),
    ),
    const SizedBox(height: 20),
    _InfoBanner(
      icon: '⚠️',
      text: 'En mode composition, Le Sage est désactivé. Bonne chance !',
      color: AppColors.warning,
    ),
  ];

  void _startComposition(BuildContext context, String subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Commencer $subject',
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: Text(
          'Tu vas simuler une épreuve de $subject. '
          'Le Sage sera désactivé pendant toute la durée.\n\nPrêt(e) ?',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(fontFamily: 'Nunito', color: AppColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Commencer',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _ExamHero extends StatelessWidget {
  final String grade;
  const _ExamHero({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A00), Color(0xFF4A1500), Color(0xFFCC4400)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Mode Examen',
                  style: TextStyle(color: Colors.white60, fontSize: 13,
                      fontFamily: 'Nunito')),
              Row(children: [
                Expanded(
                  child: Text(
                    grade.isNotEmpty ? 'BAC / BEPC $grade' : 'Prépare-toi !',
                    style: const TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w900, fontFamily: 'Nunito'),
                  ),
                ),
                const Text('📚', style: TextStyle(fontSize: 36)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _Tab(label: 'Préparation', active: selected == 0,
            onTap: () => onChanged(0)),
        _Tab(label: 'Composition', active: selected == 1,
            onTap: () => onChanged(1)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: AppColors.shadow, blurRadius: 8,
                    offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            )),
          ),
        ),
      ),
    );
  }
}

// ── Subject Prep Card ─────────────────────────────────────────────────────────

class _SubjectPrepCard extends StatelessWidget {
  final String subject;
  const _SubjectPrepCard({required this.subject});

  static const _icons = {
    'Mathématiques': '📐',
    'Physique-Chimie': '⚗️',
    'Français': '📖',
    'Histoire-Géographie': '🌍',
    'Anglais': '🇬🇧',
    'Sciences de la Vie et de la Terre': '🌱',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[subject] ?? '📚';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.08),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(subject, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.onSurface)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Réviser',
              style: TextStyle(color: AppColors.primary, fontFamily: 'Nunito',
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Composition Card ──────────────────────────────────────────────────────────

class _CompositionCard extends StatelessWidget {
  final String icon, title, duration;
  final VoidCallback onStart;
  const _CompositionCard({
    required this.icon, required this.title,
    required this.duration, required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 13,
                  color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(duration, style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
          ],
        )),
        FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Commencer',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String icon, text;
  final Color color;
  const _InfoBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: color, height: 1.4))),
      ]),
    );
  }
}
