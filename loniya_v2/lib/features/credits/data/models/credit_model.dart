import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';

part 'credit_model.g.dart';

@HiveType(typeId: 20)
class CreditModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final int base;           // 20 garantis, jamais déduits
  @HiveField(2) final int bonus;          // gagnés ce mois (plafond 40)
  @HiveField(3) final String resetMonth;  // "2025-04" — mois du dernier reset
  @HiveField(4) final int totalEarned;    // cumulatif all-time
  @HiveField(5) final int totalSpent;     // cumulatif all-time

  const CreditModel({
    required this.userId,
    this.base         = 20,
    this.bonus        = 0,
    required this.resetMonth,
    this.totalEarned  = 0,
    this.totalSpent   = 0,
  });

  int get total          => base + bonus;
  int get bonusRemaining => AppConstants.creditBonusCap - bonus;

  /// Vérifie et remet à zéro les crédits bonus si on a changé de mois.
  CreditModel checkMonthReset() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (resetMonth == currentMonth) return this;
    return copyWith(bonus: 0, resetMonth: currentMonth);
  }

  /// Ajoute des crédits bonus (respecte le plafond mensuel de 40).
  CreditModel addBonus(int amount) {
    final capped = (bonus + amount).clamp(0, AppConstants.creditBonusCap);
    final added  = capped - bonus;
    return copyWith(
      bonus:       capped,
      totalEarned: totalEarned + added,
    );
  }

  /// Dépense des crédits (base d'abord protégé, déduit du bonus).
  /// Retourne null si solde insuffisant.
  CreditModel? spend(int amount) {
    if (bonus < amount) return null;
    return copyWith(
      bonus:      bonus - amount,
      totalSpent: totalSpent + amount,
    );
  }

  CreditModel copyWith({
    int? base, int? bonus, String? resetMonth,
    int? totalEarned, int? totalSpent,
  }) =>
      CreditModel(
        userId:       userId,
        base:         base        ?? this.base,
        bonus:        bonus       ?? this.bonus,
        resetMonth:   resetMonth  ?? this.resetMonth,
        totalEarned:  totalEarned ?? this.totalEarned,
        totalSpent:   totalSpent  ?? this.totalSpent,
      );
}
