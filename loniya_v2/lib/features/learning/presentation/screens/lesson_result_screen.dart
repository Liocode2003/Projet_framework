import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LessonResultScreen extends StatelessWidget {
  final String lessonId;
  const LessonResultScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Résultat leçon — Phase 6')),
    );
  }
}
