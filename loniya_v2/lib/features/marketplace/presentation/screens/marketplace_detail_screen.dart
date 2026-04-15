import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  final String contentId;
  const MarketplaceDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contenu #$contentId')),
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Détail contenu — Phase 5')),
    );
  }
}
