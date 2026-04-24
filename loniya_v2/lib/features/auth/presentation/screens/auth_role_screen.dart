import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class AuthRoleScreen extends ConsumerStatefulWidget {
  const AuthRoleScreen({super.key});

  @override
  ConsumerState<AuthRoleScreen> createState() => _AuthRoleScreenState();
}

class _AuthRoleScreenState extends ConsumerState<AuthRoleScreen> {
  String? _selectedRole;

  static const _roles = [
    _RoleOption(
      role: AppConstants.roleStudent,
      label: 'Élève',
      emoji: '📚',
      description: 'J\'apprends et progresse à mon rythme',
      colors: [Color(0xFF1A0A3E), AppColors.primary],
    ),
    _RoleOption(
      role: AppConstants.roleTeacher,
      label: 'Enseignant',
      emoji: '🎓',
      description: 'Je gère ma classe et partage des contenus',
      colors: [Color(0xFF003D35), AppColors.teal],
    ),
    _RoleOption(
      role: AppConstants.roleParent,
      label: 'Parent',
      emoji: '👨‍👩‍👧',
      description: 'Je suis la progression de mon enfant',
      colors: [Color(0xFF3D1A00), AppColors.accent],
    ),
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
        authNotifierProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              const Text(
                'Qui es-tu ?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisis ton profil pour personnaliser yikri.',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              // Role cards
              Expanded(
                child: Column(
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role.role;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role.role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: role.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? role.colors.last.withOpacity(0.35)
                                  : AppColors.shadow.withOpacity(0.08),
                              blurRadius: isSelected ? 20 : 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          // Emoji
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : role.colors.last.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(role.emoji,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.label,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.description,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected
                                ? Colors.white
                                : AppColors.grey300,
                            size: 24,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),

              AppButton(
                label: 'Continuer',
                prefixIcon: Icons.arrow_forward_rounded,
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
  final String role, label, emoji, description;
  final List<Color> colors;
  const _RoleOption({
    required this.role, required this.label,
    required this.emoji, required this.description,
    required this.colors,
  });
}
