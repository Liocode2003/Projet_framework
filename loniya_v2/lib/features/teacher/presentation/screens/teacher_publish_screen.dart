import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class TeacherPublishScreen extends ConsumerStatefulWidget {
  const TeacherPublishScreen({super.key});

  @override
  ConsumerState<TeacherPublishScreen> createState() => _TeacherPublishScreenState();
}

class _TeacherPublishScreenState extends ConsumerState<TeacherPublishScreen> {
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  String? _subject;
  String? _grade;
  int _price = AppConstants.coursePrice;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publier un cours',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Informations du cours'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre du cours',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Matière & classe cible'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(
                labelText: 'Matière',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: AppConstants.subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _grade,
              decoration: const InputDecoration(
                labelText: 'Classe cible',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: AppConstants.studentGrades
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _grade = v),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Prix'),
            const SizedBox(height: 8),
            _PriceSelector(
              selected: _price,
              onChanged: (p) => setState(() => _price = p),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _subject != null && _grade != null &&
                        _titleCtrl.text.trim().isNotEmpty
                    ? _publish
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Publier le cours',
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _publish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cours publié avec succès ! 🎉',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800,
        color: AppColors.onSurface));
  }
}

class _PriceSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _PriceSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (AppConstants.coursePrice, '${AppConstants.coursePrice} FCFA', '💰'),
      (0, 'Gratuit', '🎁'),
    ];

    return Row(
      children: options.map((opt) {
        final (price, label, icon) = opt;
        final isSelected = selected == price;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(price),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: price == 0 ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.onSurface)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
