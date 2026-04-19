import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../teacher/data/models/purchase_model.dart';
import '../../domain/entities/content_entity.dart';
import '../providers/marketplace_provider.dart';

// ── Purchase providers ─────────────────────────────────────────────────────────

final _contentPriceProvider = Provider.family<int, String>((ref, contentId) {
  final db = ref.read(databaseServiceProvider);
  return db.getMarketplaceItem(contentId)?.priceFcfa ?? 0;
});

final _isPurchasedProvider = Provider.family<bool, String>((ref, contentId) {
  final db = ref.read(databaseServiceProvider);
  final userId = ref.read(authNotifierProvider).userId ?? '';
  return db.hasPurchased(userId, contentId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MarketplaceDetailScreen extends ConsumerWidget {
  final String contentId;
  const MarketplaceDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentDetailProvider(contentId));

    return contentAsync.when(
      loading: () => const Scaffold(body: InlineLoader()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(contentDetailProvider(contentId)),
        ),
      ),
      data: (content) => _DetailView(content: content),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final ContentEntity content;
  const _DetailView({required this.content});

  static const _subjectColors = {
    'Mathématiques':      AppColors.primary,
    'Français':           AppColors.secondary,
    'Sciences':           AppColors.orientation,
    'Histoire-Géographie': AppColors.tertiary,
    'Physique-Chimie':    AppColors.aiTutor,
  };

  Color get _color => _subjectColors[content.subject] ?? AppColors.grey500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(downloadNotifierProvider)[content.id];
    final isDownloading = dlState?.isDownloading ?? false;
    final progress     = dlState?.progress ?? 0.0;
    final hasError     = dlState?.hasError ?? false;
    final errorMsg     = dlState?.error;
    final priceFcfa    = ref.watch(_contentPriceProvider(content.id));
    final isPurchased  = ref.watch(_isPurchasedProvider(content.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_color, _color.withOpacity(0.7)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        content.subject.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w900,
                          color: Colors.white54, fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(content.title, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 12),

                Wrap(spacing: 8, runSpacing: 6, children: [
                  _MetaChip(content.gradeLevel, Icons.school_outlined),
                  _MetaChip(content.subject, Icons.book_outlined),
                  _MetaChip(content.typeLabel, Icons.category_outlined),
                  _MetaChip(content.formattedSize, Icons.storage_outlined),
                  _MetaChip(
                    '${content.rating.toStringAsFixed(1)} ★',
                    Icons.star_outline_rounded,
                    color: AppColors.xpGold,
                  ),
                  _MetaChip(
                    '${content.downloadCount} téléch.',
                    Icons.download_outlined,
                  ),
                  // Price chip
                  if (priceFcfa > 0)
                    _MetaChip(
                      isPurchased ? 'Acheté ✓' : '$priceFcfa FCFA',
                      isPurchased
                          ? Icons.check_circle_rounded
                          : Icons.sell_rounded,
                      color: isPurchased
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                ]),
                const SizedBox(height: 20),

                Text('Description', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text(content.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),

                if (content.tags.isNotEmpty) ...[
                  Text('Mots-clés', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: content.tags.map((t) => Chip(
                      label: Text(t, style: AppTextStyles.labelSmall),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                if (isDownloading) ...[
                  _ProgressCard(progress: progress),
                  const SizedBox(height: 16),
                ],

                if (hasError && errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Actions ──────────────────────────────────────────
                const SizedBox(height: 8),
                if (content.isDownloaded) ...[
                  AppButton(
                    label: 'Ouvrir le contenu',
                    prefixIcon: Icons.play_circle_rounded,
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    onPressed: () => context.go(
                      '${RouteNames.learning}/${content.id}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Supprimer du téléphone',
                    variant: AppButtonVariant.outlined,
                    prefixIcon: Icons.delete_outline_rounded,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ] else if (priceFcfa > 0 && !isPurchased) ...[
                  // Paid content not yet purchased
                  AppButton(
                    label: 'Acheter — $priceFcfa FCFA',
                    prefixIcon: Icons.shopping_cart_rounded,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    onPressed: () =>
                        _showPurchaseDialog(context, ref, priceFcfa),
                  ),
                ] else ...[
                  AppButton(
                    label: isDownloading
                        ? 'Téléchargement en cours...'
                        : 'Télécharger (${content.formattedSize})',
                    prefixIcon: isDownloading ? null : Icons.download_rounded,
                    isLoading: isDownloading,
                    onPressed: isDownloading
                        ? null
                        : () => ref
                            .read(downloadNotifierProvider.notifier)
                            .download(content.id),
                  ),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
      BuildContext context, WidgetRef ref, int price) {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Paiement mobile'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Montant : $price FCFA\n'
                  'Payez via Orange Money / Moov Money puis entrez le code de transaction.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code de transaction',
                    hintText: 'Ex: 2401234567',
                    prefixIcon: Icon(Icons.receipt_long_rounded),
                  ),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 8
                          ? 'Code trop court (min. 8 chiffres)'
                          : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);
                      await Future.delayed(
                          const Duration(seconds: 2)); // simulate

                      final db = ref.read(databaseServiceProvider);
                      final userId =
                          ref.read(authNotifierProvider).userId ?? '';
                      final item = db.getMarketplaceItem(content.id);

                      final purchase = PurchaseModel(
                        id: const Uuid().v4(),
                        userId: userId,
                        contentId: content.id,
                        contentTitle: content.title,
                        priceFcfa: price,
                        purchasedAt: DateTime.now().toIso8601String(),
                        paymentRef: codeCtrl.text.trim(),
                        teacherId: item?.authorId ?? '',
                      );
                      await db.savePurchase(purchase);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Achat confirmé ! Vous pouvez maintenant télécharger.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        // Invalidate to refresh purchase state
                        ref.invalidate(_isPurchasedProvider(content.id));
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Payer $price FCFA'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce contenu ?'),
        content: Text(
          '${content.title} sera supprimé de votre appareil. '
          'Vous pourrez le télécharger à nouveau plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(downloadNotifierProvider.notifier).delete(content.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.download_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Text('Téléchargement en cours...',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.info)),
          const Spacer(),
          Text('${(progress * 100).toInt()}%',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.info)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.grey200,
            color: AppColors.info,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text('Compression + chiffrement AES-256 en cours',
            style: AppTextStyles.caption),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _MetaChip(this.label, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: c)),
      ]),
    );
  }
}
