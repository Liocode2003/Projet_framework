import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class AuthPinScreen extends ConsumerStatefulWidget {
  const AuthPinScreen({super.key});

  @override
  ConsumerState<AuthPinScreen> createState() => _AuthPinScreenState();
}

class _AuthPinScreenState extends ConsumerState<AuthPinScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  String? _localError;

  List<String> get _currentPin => _isConfirming ? _confirmPin : _pin;

  void _addDigit(String digit) {
    if (_currentPin.length >= 4) return;
    setState(() { _currentPin.add(digit); _localError = null; });
    if (_currentPin.length == 4) _onPinComplete();
  }

  void _removeDigit() {
    if (_currentPin.isEmpty) return;
    setState(() => _currentPin.removeLast());
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirming) {
      setState(() => _isConfirming = true);
      return;
    }
    // Validate match
    if (_pin.join() != _confirmPin.join()) {
      setState(() {
        _localError = 'Les codes ne correspondent pas. Réessayez.';
        _confirmPin.clear();
      });
      return;
    }
    // Delegate to notifier
    await ref.read(authNotifierProvider.notifier).createPin(_pin.join());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        context.go(RouteNames.home);
      } else if (next.errorMessage != null) {
        setState(() {
          _localError = next.errorMessage;
          _pin.clear();
          _confirmPin.clear();
          _isConfirming = false;
        });
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final isLoading = ref.watch(
      authNotifierProvider.select((s) => s.isLoading),
    );
    final displayError = _localError;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Code PIN')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _isConfirming ? 'Confirmez votre PIN' : 'Créez votre PIN',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Répétez votre code à 4 chiffres'
                  : 'Ce code sécurisera l\'accès à l\'application',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _currentPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.grey200,
                    border: Border.all(
                      color: displayError != null
                          ? AppColors.error
                          : (filled ? AppColors.primary : AppColors.grey300),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            if (displayError != null) ...[
              const SizedBox(height: 16),
              Text(displayError,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error)),
            ],
            if (isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            const Spacer(),
            _NumPad(onDigit: _addDigit, onDelete: _removeDigit),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  const _NumPad({required this.onDigit, required this.onDelete});

  static const _rows = [
    ['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: _rows.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((d) {
            if (d.isEmpty) return const SizedBox(width: 72, height: 72);
            if (d == 'del') {
              return _NumKey(
                onTap: onDelete,
                child: const Icon(Icons.backspace_outlined, size: 22),
              );
            }
            return _NumKey(
              onTap: () => onDigit(d),
              child: Text(d, style: AppTextStyles.headlineLarge),
            );
          }).toList(),
        )).toList(),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _NumKey({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72, height: 72,
        child: Center(child: child),
      ),
    );
  }
}
