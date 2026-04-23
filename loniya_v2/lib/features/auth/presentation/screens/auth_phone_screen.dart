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

class AuthPhoneScreen extends ConsumerStatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  ConsumerState<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends ConsumerState<AuthPhoneScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _isRegister = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).sendOtp(_phoneCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.otpSent) {
        context.go('${RouteNames.authPhone}/otp', extra: _phoneCtrl.text.trim());
      }
    });

    final isLoading = ref.watch(authNotifierProvider.select((s) => s.isLoading));
    final error     = ref.watch(authNotifierProvider.select((s) => s.errorMessage));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Hero
          Container(
            height: size.height * 0.38,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0F06), AppColors.primaryDark, AppColors.primary],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 30, spreadRadius: 4),
                      ],
                    ),
                    child: const Center(
                      child: Text('y', style: TextStyle(
                        color: Colors.white, fontSize: 40,
                        fontWeight: FontWeight.w900, fontFamily: 'Nunito',
                      )),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('yikri', style: TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w900, fontFamily: 'Nunito',
                    letterSpacing: 1,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister ? 'Crée ton compte gratuitement' : 'Content de te revoir !',
                    style: TextStyle(color: Colors.white.withOpacity(0.65),
                        fontSize: 13, fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ),
          ),

          // Formulaire
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          _TabBtn(label: 'Se connecter',
                              active: !_isRegister,
                              onTap: () => setState(() => _isRegister = false)),
                          _TabBtn(label: 'S\'inscrire',
                              active: _isRegister,
                              onTap: () => setState(() => _isRegister = true)),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          hintText: '+226 XX XX XX XX',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (v.trim().length < 8) return 'Numéro invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v.length < AppConstants.minPasswordLength) {
                            return 'Minimum ${AppConstants.minPasswordLength} caractères';
                          }
                          return null;
                        },
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.error))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 28),
                      AppButton(
                        label: _isRegister ? 'Créer mon compte' : 'Se connecter',
                        prefixIcon: _isRegister
                            ? Icons.person_add_rounded
                            : Icons.login_rounded,
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Mode démo : code OTP = 1234',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant))),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: AppColors.shadow, blurRadius: 8,
                    offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            )),
          ),
        ),
      ),
    );
  }
}
