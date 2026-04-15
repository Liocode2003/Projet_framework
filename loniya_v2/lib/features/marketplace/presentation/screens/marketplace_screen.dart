import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../domain/entities/content_entity.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/filter_bar.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(marketplaceFilterProvider);
    final contentsAsync = ref.watch(marketplaceContentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            title: const Text('Marketplace'),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: filter.showDownloadedOnly,
                  child: const Icon(Icons.download_done_rounded),
                ),
                tooltip: 'Téléchargements',
                onPressed: () => ref
                    .read(marketplaceFilterProvider.notifier)
                    .update((s) => s.copyWith(
                          showDownloadedOnly: !s.showDownloadedOnly,
                        )),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _SearchBar(
                onChanged: (q) => ref
                    .read(marketplaceFilterProvider.notifier)
                    .update((s) => s.copyWith(query: q)),
              ),
            ),
          ),

          // ─── Filter chips ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FilterBar(
              currentFilter: filter,
              onFilterChanged: (f) =>
                  ref.read(marketplaceFilterProvider.notifier).state = f,
            ),
          ),

          // ─── Filter summary ───────────────────────────────────────────
          if (filter.hasActiveFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(children: [
                  Text(
                    filter.showDownloadedOnly
                        ? 'Affichage : téléchargés uniquement'
                        : 'Filtres actifs',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(marketplaceFilterProvider.notifier).state =
                            const MarketplaceFilter(),
                    child: const Text('Effacer',
                        style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ),
            ),

          // ─── Content list ─────────────────────────────────────────────
          contentsAsync.when(
            loading: () => const SliverToBoxAdapter(child: InlineLoader()),
            error: (e, _) => SliverToBoxAdapter(
              child: AppErrorWidget(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(marketplaceContentsProvider),
              ),
            ),
            data: (contents) {
              if (contents.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: filter.hasActiveFilters
                        ? Icons.search_off_rounded
                        : Icons.store_rounded,
                    title: filter.hasActiveFilters
                        ? 'Aucun contenu trouvé'
                        : 'Catalogue vide',
                    subtitle: filter.hasActiveFilters
                        ? 'Essayez d\'autres filtres'
                        : 'Les contenus apparaîtront ici',
                    color: AppColors.marketplace,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ContentCard(
                      content: contents[i],
                      onTap: () => context.go(
                        '${RouteNames.marketplace}/${contents[i].id}',
                        extra: contents[i],
                      ),
                    ),
                    childCount: contents.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un contenu...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
