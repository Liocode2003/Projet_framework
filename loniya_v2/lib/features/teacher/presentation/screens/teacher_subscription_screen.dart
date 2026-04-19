import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/teacher_provider.dart';

class TeacherSubscriptionScreen extends ConsumerStatefulWidget {
  const TeacherSubscriptionScreen({super.key});

  @override
  ConsumerState<TeacherSubscriptionScreen> createState() =>
      _TeacherSubscriptionScreenState();
}

class _TeacherSubscriptionScreenState
    extends ConsumerState<TeacherSubscriptionScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(teacherNotifierProvider.notifier)
        .subscribe(_codeCtrl.text);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Abonnement enseignant'),
        backgroundColor: AppColors.teacher,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Plan card ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teacher, Color(0xFF01579B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.school_rounded,
                  color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                '2 000 FCFA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Nunito',
                ),
              ),
              const Text(
                'par an',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...[
                '✓ Publiez des cours, exercices et documents',
                '✓ Percevez 150–200 FCFA par contenu vendu',
                '✓ Tableau de bord revenus en temps réel',
                '✓ Classe Wi-Fi locale illimitée',
                '✓ Badge enseignant vérifié',
              ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(f,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              )),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Payment form ──────────────────────────────────────────────
          Text('Paiement mobile', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Entrez le code de transaction reçu après votre paiement Orange Money / Moov Money.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: TextFormField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Code de transaction',
                hintText: 'Ex: 2401234567',
                prefixIcon: const Icon(Icons.receipt_long_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 8) {
                  return 'Le code doit contenir au moins 8 caractères.';
                }
                return null;
              },
            ),
          ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(state.errorMessage!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teacher,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: state.isLoading ? null : _pay,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_open_rounded),
              label: Text(
                state.isLoading ? 'Validation…' : 'Activer mon abonnement',
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Votre paiement est traité localement.\n'
              'Aucune donnée bancaire n\'est transmise.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ),
        ]),
      ),
    );
  }
}
