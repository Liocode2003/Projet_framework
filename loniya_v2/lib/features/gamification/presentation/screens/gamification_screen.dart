import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progression')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.emoji_events_rounded,
        title: 'Gamification en cours',
        subtitle: 'Disponible à la Phase 8',
        color: AppColors.gamification,
      ),
    );
  }
}
