import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Enseignant')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.cast_for_education_rounded,
        title: 'Dashboard enseignant en cours',
        subtitle: 'Disponible à la Phase 12',
        color: AppColors.teacher,
      ),
    );
  }
}
