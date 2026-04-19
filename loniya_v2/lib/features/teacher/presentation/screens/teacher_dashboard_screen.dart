import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/teacher_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherNotifierProvider);

    ref.listen<TeacherState>(teacherNotifierProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(teacherNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(teacherNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.teacher, Color(0xFF01579B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                title: Row(children: [
                  const Icon(Icons.cast_for_education_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Text('Espace Enseignant',
                      style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
                  if (state.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: AppColors.xpGold, size: 16),
                  ],
                ]),
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                collapseMode: CollapseMode.pin,
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                // ── Subscription card ─────────────────────────────────
                _SubscriptionCard(state: state),

                // ── Verification ──────────────────────────────────────
                _VerificationCard(state: state),

                // ── Revenue summary ───────────────────────────────────
                if (state.hasActiveSubscription)
                  _RevenueCard(state: state),

                // ── Published content ─────────────────────────────────
                if (state.hasActiveSubscription &&
                    state.publishedContent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text('Mes contenus publiés',
                        style: AppTextStyles.titleMedium),
                  ),
                  ...state.publishedContent.map(
                    (item) => _ContentTile(
                      item: item,
                      earnings:
                          state.earningsByContent[item.id] ?? 0,
                    ),
                  ),
                ],

                if (state.hasActiveSubscription &&
                    state.publishedContent.isEmpty)
                  _EmptyContentHint(),

                const SizedBox(height: 80),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription card ────────────────────────────────────────────────────────

class _SubscriptionCard extends ConsumerWidget {
  final TeacherState state;
  const _SubscriptionCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = state.subscription;
    final active = state.hasActiveSubscription;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [AppColors.success, AppColors.secondaryDark]
              : [AppColors.warning, const Color(0xFFBF360C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            active
                ? Icons.verified_user_rounded
                : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                active ? 'Abonnement actif' : 'Abonnement requis',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                active
                    ? 'Expire le ${sub!.formattedExpiry} · ${sub.daysRemaining} j restants'
                    : '2 000 FCFA / an — publiez vos cours',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
            ]),
          ),
        ]),
        if (!active) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.warning,
              ),
              onPressed: () =>
                  context.push(RouteNames.teacherSubscription),
              child: const Text('S\'abonner maintenant'),
            ),
          ),
        ],
        if (active && sub!.daysRemaining < 30) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white)),
              onPressed: () =>
                  context.push(RouteNames.teacherSubscription),
              child: const Text('Renouveler'),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Verification card ────────────────────────────────────────────────────────

class _VerificationCard extends ConsumerWidget {
  final TeacherState state;
  const _VerificationCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = state.subscription;
    final verified = state.isVerified;
    final requested = sub?.hasRequestedVerification ?? false;

    Color bg;
    IconData icon;
    String title;
    String subtitle;

    if (verified) {
      bg = AppColors.successLight;
      icon = Icons.verified_rounded;
      title = 'Enseignant vérifié';
      subtitle = 'Votre badge de vérification est affiché sur vos contenus.';
    } else if (requested) {
      bg = AppColors.warningLight;
      icon = Icons.hourglass_top_rounded;
      title = 'Vérification en cours';
      subtitle = 'Votre demande est en cours de traitement par l\'équipe LONIYA.';
    } else {
      bg = AppColors.surfaceVariant;
      icon = Icons.verified_outlined;
      title = 'Obtenir la vérification';
      subtitle = 'Les enseignants vérifiés gagnent 3× plus de confiance des élèves.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.teacher, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        if (!verified && !requested && state.hasActiveSubscription)
          TextButton(
            onPressed: () =>
                ref.read(teacherNotifierProvider.notifier).requestVerification(),
            child: const Text('Demander'),
          ),
      ]),
    );
  }
}

// ─── Revenue card ─────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final TeacherState state;
  const _RevenueCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.trending_up_rounded,
              color: AppColors.teacher, size: 22),
          const SizedBox(width: 8),
          Text('Revenus', style: AppTextStyles.titleMedium),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _RevenueStat(
              label: 'Total',
              value: '${state.totalEarnings} FCFA',
              color: AppColors.success,
            ),
          ),
          Expanded(
            child: _RevenueStat(
              label: 'Ce mois',
              value: '${state.thisMonthEarnings} FCFA',
              color: AppColors.teacher,
            ),
          ),
          Expanded(
            child: _RevenueStat(
              label: 'Ventes',
              value: '${state.revenueItems.length}',
              color: AppColors.levelPurple,
            ),
          ),
        ]),
        if (state.revenueItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push(RouteNames.teacherRevenue),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('Voir le détail'),
          ),
        ],
      ]),
    );
  }
}

class _RevenueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RevenueStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'Nunito',
          )),
      Text(label,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.onSurfaceVariant)),
    ]);
  }
}

// ─── Content tile ─────────────────────────────────────────────────────────────

class _ContentTile extends StatelessWidget {
  final dynamic item;
  final int earnings;
  const _ContentTile({required this.item, required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teacher.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
              child: Icon(Icons.book_rounded,
                  color: AppColors.teacher, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.title as String,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              '${item.gradeLevel} · ${item.subject}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$earnings FCFA',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              )),
          Text('${item.downloadCount} téléch.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}

class _EmptyContentHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.teacher.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teacher.withOpacity(0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.add_circle_outline_rounded,
            color: AppColors.teacher, size: 40),
        const SizedBox(height: 12),
        Text('Publiez votre premier contenu',
            style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'Allez dans l\'onglet Contenus pour ajouter et vendre vos cours.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teacher),
          onPressed: () => context.go(RouteNames.marketplace),
          icon: const Icon(Icons.store_rounded, size: 18),
          label: const Text('Marketplace'),
        ),
      ]),
    );
  }
}
