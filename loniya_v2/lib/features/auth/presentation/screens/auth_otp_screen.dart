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

class AuthOtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const AuthOtpScreen({super.key, required this.phone});

  @override
  ConsumerState<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends ConsumerState<AuthOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 4) return;
    await ref.read(authNotifierProvider.notifier).verifyOtp(_otp);
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 4) _verify();
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.otpVerified) {
        context.go('${RouteNames.authPhone}/role');
      } else if (next.status == AuthStatus.error) {
        _clearBoxes();
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
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).clearError();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Code de vérification', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Code envoyé au +226 ${widget.phone}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => _OtpBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onDigitEntered(i, v),
                  hasError: error != null,
                )),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 40),
              AppButton(
                label: 'Vérifier',
                onPressed: _verify,
                isLoading: isLoading,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authNotifierProvider.notifier)
                          .sendOtp(widget.phone),
                  child: const Text('Renvoyer le code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, height: 64,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.headlineLarge,
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.outline,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          fillColor: AppColors.surfaceVariant,
          filled: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
