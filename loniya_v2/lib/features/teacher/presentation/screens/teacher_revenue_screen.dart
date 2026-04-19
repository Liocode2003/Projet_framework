import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/teacher_provider.dart';
import '../../data/models/purchase_model.dart';

class TeacherRevenueScreen extends ConsumerWidget {
  const TeacherRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes revenus'),
        backgroundColor: AppColors.teacher,
        foregroundColor: Colors.white,
      ),
      body: state.revenueItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.grey400),
                  SizedBox(height: 16),
                  Text('Aucune vente pour le moment.',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary header
                _SummaryHeader(state: state),
                const SizedBox(height: 20),
                Text('Historique des ventes',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                ...state.revenueItems.map((p) => _PurchaseTile(p: p)),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final TeacherState state;
  const _SummaryHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white, size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total des revenus',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              '${state.totalEarnings} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
              ),
            ),
            Text(
              'Ce mois : ${state.thisMonthEarnings} FCFA · ${state.revenueItems.length} vente(s)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final PurchaseModel p;
  const _PurchaseTile({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
              child: Icon(Icons.sell_rounded,
                  color: AppColors.success, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(p.contentTitle,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              '${p.formattedDate} · Réf: ${p.paymentRef.length > 8 ? p.paymentRef.substring(0, 8) : p.paymentRef}…',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ]),
        ),
        Text(
          '+${p.priceFcfa} FCFA',
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
            fontSize: 15,
          ),
        ),
      ]),
    );
  }
}
