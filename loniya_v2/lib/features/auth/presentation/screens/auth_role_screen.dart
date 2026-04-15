import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class AuthRoleScreen extends ConsumerStatefulWidget {
  const AuthRoleScreen({super.key});

  @override
  ConsumerState<AuthRoleScreen> createState() => _AuthRoleScreenState();
}

class _AuthRoleScreenState extends ConsumerState<AuthRoleScreen> {
  String? _selectedRole;

  static const List<_RoleOption> _roles = [
    _RoleOption(role: AppConstants.roleStudent, label: 'Élève',
      description: 'J\'apprends et progresse à mon rythme',
      icon: Icons.school_rounded, color: AppColors.learning),
    _RoleOption(role: AppConstants.roleTeacher, label: 'Enseignant',
      description: 'Je gère ma classe et partage des contenus',
      icon: Icons.cast_for_education_rounded, color: AppColors.teacher),
    _RoleOption(role: AppConstants.roleParent, label: 'Parent',
      description: 'Je suis la progression de mon enfant',
      icon: Icons.family_restroom_rounded, color: AppColors.orientation),
  ];

  Future<void> _continue() async {
    if (_selectedRole == null) return;
    await ref.read(authNotifierProvider.notifier).saveRole(_selectedRole!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.roleSelected) {
        context.go('${RouteNames.authPhone}/consent');
      }
    });

    final isLoading = ref.watch(
      authNotifierProvider.select((s) => s.isLoading),
    );
    final error = ref.watch(
      authNotifierProvider.select((s) => s.errorMessage),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Votre profil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qui êtes-vous ?', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Choisissez votre profil pour personnaliser l\'expérience.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final role = _roles[i];
                    final isSelected = _selectedRole == role.role;
                    return AppCard(
                      onTap: () => setState(() => _selectedRole = role.role),
                      backgroundColor:
                          isSelected ? role.color.withOpacity(0.08) : null,
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: role.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(role.icon, color: role.color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role.label, style: AppTextStyles.titleLarge),
                                const SizedBox(height: 2),
                                Text(role.description,
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: role.color, size: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'Continuer',
                onPressed: _selectedRole == null ? null : _continue,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String role, label, description;
  final IconData icon;
  final Color color;
  const _RoleOption({required this.role, required this.label,
    required this.description, required this.icon, required this.color});
}
