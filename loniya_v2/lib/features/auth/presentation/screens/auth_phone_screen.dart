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
    // Listen for state changes and navigate accordingly
    final authState = ref.read(authNotifierProvider);
    _navigateIfNeeded(authState);
  }

  void _navigateIfNeeded(AuthState state) {
    if (!mounted) return;
    if (state.status == AuthStatus.otpSent) {
      context.go(
        '${RouteNames.authPhone}/otp',
        extra: state.phone ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to state changes
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      _navigateIfNeeded(next);
    });

    final isLoading = ref.watch(
      authNotifierProvider.select((s) => s.isLoading),
    );
    final error = ref.watch(
      authNotifierProvider.select((s) => s.errorMessage),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('L',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900,
                            color: Colors.white, fontFamily: 'Nunito'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Bienvenue !', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre numéro de téléphone pour commencer.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                Text('Numéro de téléphone', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 12,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Numéro requis';
                    final cleaned = v.replaceAll(RegExp(r'\D'), '');
                    if (cleaned.length < 8) return 'Numéro invalide (min 8 chiffres)';
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: '07XXXXXXXX',
                    prefixText: '+226 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: 32),
                AppButton(
                  label: 'Recevoir le code',
                  onPressed: _submit,
                  isLoading: isLoading,
                  prefixIcon: Icons.sms_outlined,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Code de démonstration : 1234',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
