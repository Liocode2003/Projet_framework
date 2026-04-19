import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .sendOtp(_phoneController.text.trim());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigateIfNeeded(ref.read(authNotifierProvider));
  }

  void _navigateIfNeeded(AuthState state) {
    if (!mounted) return;
    if (state.status == AuthStatus.otpSent) {
      context.go('${RouteNames.authPhone}/otp', extra: state.phone ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) => _navigateIfNeeded(next));

    final isLoading = ref.watch(authNotifierProvider.select((s) => s.isLoading));
    final error     = ref.watch(authNotifierProvider.select((s) => s.errorMessage));
    final size      = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // ── Gradient top section ───────────────────────────────────────
          Container(
            height: size.height * 0.40,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A3E),
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LONIYA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rejoins l\'aventure',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card form section ───────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ton numéro',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nous t\'enverrons un code de vérification.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 12,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Numéro requis';
                          if (v.replaceAll(RegExp(r'\D'), '').length < 8) {
                            return 'Numéro invalide (min 8 chiffres)';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: '07 XX XX XX',
                          prefixText: '+226  ',
                          prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
                          counterText: '',
                          labelText: 'Numéro de téléphone',
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(error,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.error)),
                            ),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 32),

                      AppButton(
                        label: 'Recevoir le code',
                        onPressed: _submit,
                        isLoading: isLoading,
                        prefixIcon: Icons.sms_rounded,
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Code de démonstration : 1234',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                        ),
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
