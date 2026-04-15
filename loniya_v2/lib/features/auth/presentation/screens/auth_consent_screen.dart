import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class AuthConsentScreen extends ConsumerStatefulWidget {
  const AuthConsentScreen({super.key});

  @override
  ConsumerState<AuthConsentScreen> createState() => _AuthConsentScreenState();
}

class _AuthConsentScreenState extends ConsumerState<AuthConsentScreen> {
  bool _dataConsent = false;
  bool _termsConsent = false;
  bool _minorConsent = false;

  bool get _canProceed => _dataConsent && _termsConsent;

  Future<void> _accept() async {
    if (!_canProceed) return;
    await ref.read(authNotifierProvider.notifier).saveConsent();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.consentGiven) {
        context.go('${RouteNames.authPhone}/pin');
      }
    });

    final isLoading = ref.watch(
      authNotifierProvider.select((s) => s.isLoading),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Consentement CIL')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CIL badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text('Protection des données — CIL Burkina Faso',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.info)),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Vos droits & données', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Conformément à la loi n°010-2004/AN sur la protection '
                'des données personnelles du Burkina Faso.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Données collectées :', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    ...[
                      'Numéro de téléphone (identification)',
                      'Progression d\'apprentissage',
                      'Scores et résultats',
                      'Préférences de langue',
                    ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.grey500),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t, style: AppTextStyles.bodySmall)),
                          ]),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Stockage : Local sur votre appareil. Aucune donnée '
                      'n\'est transmise sans votre accord.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ConsentCheckbox(
                value: _dataConsent,
                onChanged: (v) => setState(() => _dataConsent = v ?? false),
                label: 'J\'accepte la collecte et l\'utilisation de mes '
                    'données à des fins éducatives.',
              ),
              const SizedBox(height: 12),
              _ConsentCheckbox(
                value: _termsConsent,
                onChanged: (v) => setState(() => _termsConsent = v ?? false),
                label: 'J\'ai lu et j\'accepte les conditions '
                    'd\'utilisation de LONIYA V2.',
              ),
              const SizedBox(height: 12),
              _ConsentCheckbox(
                value: _minorConsent,
                onChanged: (v) => setState(() => _minorConsent = v ?? false),
                label: 'Si l\'utilisateur est mineur, le tuteur légal a '
                    'donné son accord. (Optionnel)',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Accepter et continuer',
                onPressed: _canProceed ? _accept : null,
                isLoading: isLoading,
                prefixIcon: Icons.check_circle_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  const _ConsentCheckbox(
      {required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: value, onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
        ),
      ]),
    );
  }
}
