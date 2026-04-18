import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/network_peer.dart';

class PeerListTile extends StatelessWidget {
  final NetworkPeer peer;
  final bool isSelected;
  final VoidCallback? onTap;

  const PeerListTile({
    super.key,
    required this.peer,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.localNetwork.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.localNetwork
              : AppColors.grey200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.localNetwork.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.computer_rounded,
              color: AppColors.localNetwork, size: 22),
        ),
        title: Text(peer.name, style: AppTextStyles.labelLarge),
        subtitle: Text(
          '${peer.ip}:${peer.port}',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.localNetwork)
            : const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey400),
      ),
    );
  }
}
