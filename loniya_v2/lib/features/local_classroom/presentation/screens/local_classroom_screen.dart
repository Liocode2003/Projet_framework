import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class LocalClassroomScreen extends StatelessWidget {
  const LocalClassroomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classe Wi-Fi')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.wifi_rounded,
        title: 'Mode classe locale en cours',
        subtitle: 'Disponible à la Phase 10',
        color: AppColors.localNetwork,
      ),
    );
  }
}
