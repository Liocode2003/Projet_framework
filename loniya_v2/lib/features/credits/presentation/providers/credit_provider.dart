import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/credit_model.dart';

// ── Box provider ──────────────────────────────────────────────────────────────
final creditBoxProvider = Provider<Box<CreditModel>>((ref) {
  return Hive.box<CreditModel>(HiveBoxes.credits);
});

// ── Credit notifier ───────────────────────────────────────────────────────────
class CreditNotifier extends StateNotifier<CreditModel?> {
  final Ref _ref;

  CreditNotifier(this._ref) : super(null) {
    _load();
  }

  String get _userId => _ref.read(currentUserProvider)?.id ?? '';

  void _load() {
    final box   = _ref.read(creditBoxProvider);
    final now   = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    var model   = box.get(_userId);

    if (model == null) {
      model = CreditModel(userId: _userId, resetMonth: month);
    } else {
      model = model.checkMonthReset();
    }
    box.put(_userId, model);
    state = model;
  }

  Future<void> addBonus(int amount, {String reason = ''}) async {
    if (state == null) return;
    final updated = state!.addBonus(amount);
    await _save(updated);
  }

  /// Dépense des crédits. Retourne true si succès.
  Future<bool> spend(int amount) async {
    if (state == null || state!.bonus < amount) return false;
    final updated = state!.spend(amount);
    if (updated == null) return false;
    await _save(updated);
    return true;
  }

  Future<void> _save(CreditModel model) async {
    final box = _ref.read(creditBoxProvider);
    await box.put(_userId, model);
    state = model;
  }

  // ── Helpers bonus par action ──────────────────────────────────────────

  Future<void> onGameLevelCompleted() =>
      addBonus(AppConstants.creditPerGame, reason: 'jeu');

  Future<void> onChallengeCompleted() =>
      addBonus(AppConstants.creditPerChallenge, reason: 'défi');

  Future<void> onPerfectQcm() =>
      addBonus(AppConstants.creditPerPerfectQcm, reason: 'qcm_parfait');

  Future<void> onStreak3Days() =>
      addBonus(AppConstants.creditPerStreak3days, reason: 'série_3j');

  Future<void> onStreak7Days() =>
      addBonus(AppConstants.creditPerStreak7days, reason: 'série_7j');
}

final creditNotifierProvider =
    StateNotifierProvider<CreditNotifier, CreditModel?>((ref) {
  return CreditNotifier(ref);
});

/// Solde total visible (base + bonus)
final creditBalanceProvider = Provider<int>((ref) {
  return ref.watch(creditNotifierProvider)?.total ?? AppConstants.creditBase;
});

/// Bonus gagnés ce mois
final creditBonusProvider = Provider<int>((ref) {
  return ref.watch(creditNotifierProvider)?.bonus ?? 0;
});
