import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../marketplace/data/models/marketplace_item_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/purchase_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class TeacherState {
  final SubscriptionModel? subscription;
  final List<PurchaseModel> revenueItems;
  final List<MarketplaceItemModel> publishedContent;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const TeacherState({
    this.subscription,
    this.revenueItems = const [],
    this.publishedContent = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasActiveSubscription => subscription?.isValid ?? false;
  bool get isVerified => subscription?.isVerified ?? false;

  int get totalEarnings =>
      revenueItems.fold(0, (s, p) => s + p.priceFcfa);

  int get thisMonthEarnings {
    final now = DateTime.now();
    return revenueItems
        .where((p) {
          final dt = DateTime.parse(p.purchasedAt);
          return dt.month == now.month && dt.year == now.year;
        })
        .fold(0, (s, p) => s + p.priceFcfa);
  }

  Map<String, int> get earningsByContent {
    final map = <String, int>{};
    for (final p in revenueItems) {
      map[p.contentId] = (map[p.contentId] ?? 0) + p.priceFcfa;
    }
    return map;
  }

  TeacherState copyWith({
    SubscriptionModel? subscription,
    List<PurchaseModel>? revenueItems,
    List<MarketplaceItemModel>? publishedContent,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) =>
      TeacherState(
        subscription: subscription ?? this.subscription,
        revenueItems: revenueItems ?? this.revenueItems,
        publishedContent: publishedContent ?? this.publishedContent,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        successMessage: successMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TeacherNotifier extends StateNotifier<TeacherState> {
  final DatabaseService _db;
  final String _userId;

  TeacherNotifier(this._db, this._userId) : super(const TeacherState()) {
    _load();
  }

  void _load() {
    final sub = _db.getSubscription(_userId);
    final revenue = _db.getTeacherRevenue(_userId);
    final content = _db.getTeacherPublishedItems(_userId);
    state = TeacherState(
      subscription: sub,
      revenueItems: revenue,
      publishedContent: content,
      isLoading: false,
    );
  }

  Future<bool> subscribe(String paymentRef) async {
    if (paymentRef.trim().length < 8) {
      state = state.copyWith(
          errorMessage: 'Code de paiement invalide (min. 8 caractères).');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(seconds: 2)); // simulate validation

    final now = DateTime.now();
    final sub = SubscriptionModel(
      userId: _userId,
      plan: 'annual',
      priceFcfa: 2000,
      startDate: now.toIso8601String(),
      expiresAt: now.add(const Duration(days: 365)).toIso8601String(),
      paymentRef: paymentRef.trim(),
      isActive: true,
    );
    await _db.saveSubscription(sub);
    state = state.copyWith(
      subscription: sub,
      isLoading: false,
      successMessage: 'Abonnement activé jusqu\'au ${sub.formattedExpiry} !',
    );
    return true;
  }

  Future<void> requestVerification() async {
    final sub = state.subscription;
    if (sub == null) return;
    final updated = sub.copyWith(
      verificationRequestedAt: DateTime.now().toIso8601String(),
    );
    await _db.saveSubscription(updated);
    state = state.copyWith(
      subscription: updated,
      successMessage: 'Demande de vérification envoyée à l\'équipe LONIYA.',
    );
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void refresh() => _load();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final teacherNotifierProvider =
    StateNotifierProvider<TeacherNotifier, TeacherState>((ref) {
  final userId = ref.watch(authNotifierProvider).userId ?? '';
  return TeacherNotifier(ref.read(databaseServiceProvider), userId);
});

/// True if the current teacher has an active subscription.
final teacherSubscriptionActiveProvider = Provider<bool>((ref) {
  return ref.watch(teacherNotifierProvider).hasActiveSubscription;
});
