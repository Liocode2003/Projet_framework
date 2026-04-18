import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/network_peer.dart';
import '../providers/local_network_provider.dart';
import '../widgets/content_transfer_tile.dart';
import '../widgets/peer_list_tile.dart';

class LocalClassroomJoinScreen extends ConsumerStatefulWidget {
  const LocalClassroomJoinScreen({super.key});

  @override
  ConsumerState<LocalClassroomJoinScreen> createState() =>
      _LocalClassroomJoinScreenState();
}

class _LocalClassroomJoinScreenState
    extends ConsumerState<LocalClassroomJoinScreen> {
  @override
  void dispose() {
    ref.read(localNetworkNotifierProvider.notifier).stopStudent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localNetworkNotifierProvider);
    final notifier = ref.read(localNetworkNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rejoindre une classe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            notifier.stopStudent();
            context.go(RouteNames.localClassroom);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Scan button ─────────────────────────────────────────────
            state.isRunning
                ? AppButton(
                    label: 'Arrêter la recherche',
                    prefixIcon: Icons.stop_rounded,
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    onPressed: notifier.stopStudent,
                  )
                : AppButton(
                    label: state.status == NetworkStatus.starting
                        ? 'Recherche en cours…'
                        : 'Rechercher un enseignant',
                    prefixIcon: Icons.search_rounded,
                    backgroundColor: AppColors.localNetwork,
                    foregroundColor: Colors.white,
                    isLoading: state.status == NetworkStatus.starting,
                    onPressed: state.status == NetworkStatus.starting
                        ? null
                        : notifier.startAsStudent,
                  ),

            // ── Error ───────────────────────────────────────────────────
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(state.errorMessage!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ),
            ],

            // ── Discovered teachers ────────────────────────────────────
            if (state.isRunning) ...[
              const SizedBox(height: 24),
              Row(children: [
                Text('Enseignants détectés',
                    style: AppTextStyles.titleMedium),
                const Spacer(),
                if (state.discoveredTeachers.isNotEmpty)
                  Text(
                    '${state.discoveredTeachers.length} trouvé(s)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
              ]),
              const SizedBox(height: 12),

              if (state.discoveredTeachers.isEmpty)
                _ScanningPlaceholder()
              else
                ...state.discoveredTeachers.map((peer) => PeerListTile(
                      peer: peer,
                      isSelected: state.selectedTeacher?.id == peer.id,
                      onTap: () => notifier.selectTeacher(peer),
                    )),
            ],

            // ── Content list ────────────────────────────────────────────
            if (state.selectedTeacher != null) ...[
              const SizedBox(height: 24),
              _ContentHeader(teacher: state.selectedTeacher!),
              const SizedBox(height: 12),

              if (state.teacherContent.isEmpty)
                _EmptyContent()
              else
                ...state.teacherContent.map((c) => ContentTransferTile(
                      content: c,
                      progress: state.downloadProgress[c.id],
                      isDownloaded: state.downloadedIds.contains(c.id),
                      onDownload: () => notifier.downloadContent(c),
                    )),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ScanningPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppColors.localNetwork,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Recherche en cours…',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Assurez-vous d\'être sur le même réseau Wi-Fi.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  final NetworkPeer teacher;

  const _ContentHeader({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.folder_open_rounded,
          color: AppColors.localNetwork, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Cours de ${teacher.name}',
          style: AppTextStyles.titleMedium,
        ),
      ),
    ]);
  }
}

class _EmptyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        const Icon(Icons.folder_off_rounded,
            size: 40, color: AppColors.grey400),
        const SizedBox(height: 10),
        Text('Aucun cours disponible',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          'L\'enseignant n\'a pas encore téléchargé de contenus.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
