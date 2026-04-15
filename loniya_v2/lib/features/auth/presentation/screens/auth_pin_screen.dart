import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

/// PIN creation screen — sets the local security PIN stored via AES-256.
/// Phase 3 (Offline Core) will inject EncryptionService for real hashing.
class AuthPinScreen extends StatefulWidget {
  const AuthPinScreen({super.key});

  @override
  State<AuthPinScreen> createState() => _AuthPinScreenState();
}

class _AuthPinScreenState extends State<AuthPinScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  String? _error;
  bool _isLoading = false;

  List<String> get _currentPin => _isConfirming ? _confirmPin : _pin;

  void _addDigit(String digit) {
    if (_currentPin.length >= 4) return;
    setState(() {
      _currentPin.add(digit);
      _error = null;
    });
    if (_currentPin.length == 4) _onPinComplete();
  }

  void _removeDigit() {
    if (_currentPin.isEmpty) return;
    setState(() => _currentPin.removeLast());
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirming) {
      setState(() => _isConfirming = true);
    } else {
      // Compare PINs
      if (_pin.join() != _confirmPin.join()) {
        setState(() {
          _error = 'Les codes ne correspondent pas. Réessayez.';
          _confirmPin.clear();
        });
        return;
      }
      await _saveAndContinue();
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    // Store a mock session — Phase 3 will encrypt properly
    final box = Hive.box(HiveBoxes.sessions);
    await box.put('current', {
      'pin_set': true,
      'created_at': DateTime.now().toIso8601String(),
      'role': 'student', // Will come from auth role in Phase 4
    });

    if (!mounted) return;
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
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
                  : 'Ce code sécurise l\'accès à l\'application',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.grey200,
                    border: Border.all(
                      color: _error != null
                          ? AppColors.error
                          : (filled ? AppColors.primary : AppColors.grey300),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],

            const Spacer(),

            // Numpad
            _NumPad(
              onDigit: _addDigit,
              onDelete: _removeDigit,
            ),
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

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: digits.map((row) => Row(
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
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
