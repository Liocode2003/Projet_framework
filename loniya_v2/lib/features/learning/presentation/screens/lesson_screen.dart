import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LessonScreen extends StatelessWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leçon $lessonId')),
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Lecteur APC — Phase 6')),
    );
  }
}
