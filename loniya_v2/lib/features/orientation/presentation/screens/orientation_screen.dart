import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class OrientationScreen extends StatelessWidget {
  const OrientationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.compass_calibration_rounded,
        title: 'Moteur orientation en cours',
        subtitle: 'Disponible à la Phase 9',
        color: AppColors.orientation,
      ),
    );
  }
}
