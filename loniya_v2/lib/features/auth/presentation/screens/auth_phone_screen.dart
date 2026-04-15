import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class AuthPhoneScreen extends StatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Simulate OTP send delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to OTP screen, passing phone number
    context.go(
      '${RouteNames.authPhone}/otp',
      extra: _phoneController.text.trim(),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Numéro requis';
    // Burkina Faso phone: starts with +226 or 0226, 8 digits
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 8) return 'Numéro invalide (min 8 chiffres)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
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

                // Logo & welcome
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
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

                // Phone field
                Text('Numéro de téléphone', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 12,
                  validator: _validatePhone,
                  decoration: const InputDecoration(
                    hintText: '07XXXXXXXX',
                    prefixText: '+226 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Recevoir le code',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  prefixIcon: Icons.sms_outlined,
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Un code à 4 chiffres sera envoyé par SMS',
                    style: AppTextStyles.caption,
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
