import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrientationResultScreen extends StatelessWidget {
  const OrientationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat orientation')),
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Résultat — Phase 9')),
    );
  }
}
