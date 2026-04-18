import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/local_network_provider.dart';

class LocalClassroomHostScreen extends ConsumerStatefulWidget {
  const LocalClassroomHostScreen({super.key});

  @override
  ConsumerState<LocalClassroomHostScreen> createState() =>
      _LocalClassroomHostScreenState();
}

class _LocalClassroomHostScreenState
    extends ConsumerState<LocalClassroomHostScreen> {
  @override
  void dispose() {
    // Stop server when leaving screen
    ref.read(localNetworkNotifierProvider.notifier).stopTeacher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localNetworkNotifierProvider);
    final notifier = ref.read(localNetworkNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mode Enseignant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            notifier.stopTeacher();
            context.go(RouteNames.localClassroom);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Server status card ───────────────────────────────────────
            _ServerStatusCard(state: state),

            const SizedBox(height: 16),

            // ── Error ────────────────────────────────────────────────────
            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(state.errorMessage!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ),

            // ── Start/Stop button ─────────────────────────────────────────
            state.isRunning
                ? AppButton(
                    label: 'Arrêter le partage',
                    prefixIcon: Icons.stop_circle_rounded,
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    onPressed: notifier.stopTeacher,
                  )
                : AppButton(
                    label: state.status == NetworkStatus.starting
                        ? 'Démarrage…'
                        : 'Démarrer le partage',
                    prefixIcon: Icons.cast_for_education_rounded,
                    backgroundColor: AppColors.teacher,
                    foregroundColor: Colors.white,
                    isLoading: state.status == NetworkStatus.starting,
                    onPressed: state.status == NetworkStatus.starting
                        ? null
                        : notifier.startAsTeacher,
                  ),

            // ── Connected info ────────────────────────────────────────────
            if (state.isRunning) ...[
              const SizedBox(height: 24),
              Text('Statut du serveur',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.wifi_tethering_rounded,
                label: 'Diffusion active',
                value: 'Port ${TeacherServer.defaultPort}',
                valueColor: AppColors.success,
              ),
              if (state.localIp != null)
                _InfoRow(
                  icon: Icons.lan_rounded,
                  label: 'Adresse IP',
                  value: state.localIp!,
                  valueColor: AppColors.info,
                ),
              _InfoRow(
                icon: Icons.folder_shared_rounded,
                label: 'Contenus partagés',
                value: '${_sharedCount()} cours disponibles',
                valueColor: AppColors.teacher,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre appareil est visible sur le réseau. '
                      'Les élèves peuvent maintenant vous rejoindre.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  int _sharedCount() {
    // Reads from Hive directly via teacher server's internal count
    return 0; // placeholder; actual count shown via TeacherServer
  }
}

class _ServerStatusCard extends StatelessWidget {
  final LocalNetworkState state;

  const _ServerStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state.isRunning ? AppColors.success : AppColors.grey400;
    final label = state.isRunning ? 'En ligne' : 'Hors ligne';
    final icon = state.isRunning
        ? Icons.wifi_tethering_rounded
        : Icons.wifi_tethering_off_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isRunning
              ? [AppColors.teacher, const Color(0xFF01579B)]
              : [AppColors.grey400, AppColors.grey600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serveur de classe',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white70)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.titleMedium
                    .copyWith(color: Colors.white)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: state.isRunning
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: state.isRunning ? Colors.greenAccent : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              state.isRunning ? 'ACTIF' : 'INACTIF',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant))),
        Text(value,
            style: AppTextStyles.labelMedium.copyWith(color: valueColor)),
      ]),
    );
  }
}
