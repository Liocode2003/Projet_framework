import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      backgroundColor: AppColors.background,
      body: const EmptyStateWidget(
        icon: Icons.store_rounded,
        title: 'Marketplace en cours',
        subtitle: 'Disponible à la Phase 5',
        color: AppColors.marketplace,
      ),
    );
  }
}
