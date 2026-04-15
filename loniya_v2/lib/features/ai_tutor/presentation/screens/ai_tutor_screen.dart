import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class AiTutorScreen extends StatelessWidget {
  const AiTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IA Tuteur')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.psychology_rounded,
        title: 'Tuteur IA en cours',
        subtitle: 'Disponible à la Phase 7',
        color: AppColors.aiTutor,
      ),
    );
  }
}
