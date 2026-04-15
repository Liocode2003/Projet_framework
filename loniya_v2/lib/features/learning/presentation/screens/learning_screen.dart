import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apprendre')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.menu_book_rounded,
        title: 'Moteur APC en cours',
        subtitle: 'Disponible à la Phase 6',
        color: AppColors.learning,
      ),
    );
  }
}
