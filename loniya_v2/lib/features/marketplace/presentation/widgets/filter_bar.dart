import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/marketplace_provider.dart';

class FilterBar extends StatelessWidget {
  final MarketplaceFilter currentFilter;
  final ValueChanged<MarketplaceFilter> onFilterChanged;

  const FilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  static const _subjects = [
    'Mathématiques', 'Français', 'Sciences',
    'Histoire-Géographie', 'Physique-Chimie', 'Anglais',
  ];
  static const _grades = [
    'CM1', 'CM2', '6ème', '5ème', '4ème', '3ème',
    '2nde', '1ère', 'Terminale',
  ];
  static const _types = ['lesson', 'exercise', 'video', 'document'];
  static const _typeLabels = {
    'lesson': 'Leçon', 'exercise': 'Exercice',
    'video': 'Vidéo', 'document': 'Document',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Subject filter
          _FilterDropdown(
            label: currentFilter.subject ?? 'Matière',
            isActive: currentFilter.subject != null,
            items: _subjects,
            onSelected: (v) => onFilterChanged(
              currentFilter.copyWith(
                subject: v,
                clearSubject: v == null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Grade filter
          _FilterDropdown(
            label: currentFilter.gradeLevel ?? 'Niveau',
            isActive: currentFilter.gradeLevel != null,
            items: _grades,
            onSelected: (v) => onFilterChanged(
              currentFilter.copyWith(
                gradeLevel: v,
                clearGrade: v == null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Type filter
          _FilterDropdown(
            label: currentFilter.type != null
                ? (_typeLabels[currentFilter.type] ?? currentFilter.type!)
                : 'Type',
            isActive: currentFilter.type != null,
            items: _types,
            itemLabels: _typeLabels,
            onSelected: (v) => onFilterChanged(
              currentFilter.copyWith(type: v, clearType: v == null),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> items;
  final Map<String, String>? itemLabels;
  final ValueChanged<String?> onSelected;

  const _FilterDropdown({
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
    this.itemLabels,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (isActive)
          const PopupMenuItem<String?>(
            value: null,
            child: Text('Tous (effacer)'),
          ),
        ...items.map((item) => PopupMenuItem<String>(
              value: item,
              child: Text(itemLabels?[item] ?? item),
            )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.grey500,
          ),
        ]),
      ),
    );
  }
}
