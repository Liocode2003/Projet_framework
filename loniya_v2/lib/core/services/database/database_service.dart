import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../constants/hive_boxes.dart';
import '../../data/models/sync_action_model.dart';
import '../../data/models/settings_model.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/auth/data/models/session_model.dart';
import '../../../features/learning/data/models/progress_model.dart';
import '../../../features/gamification/data/models/gamification_model.dart';
import '../../../features/gamification/data/models/badge_model.dart';
import '../../../features/marketplace/data/models/marketplace_item_model.dart';
import '../../../features/ai_tutor/data/models/ai_cache_entry_model.dart';
import '../../../features/local_classroom/data/models/classroom_model.dart';
import '../../../features/teacher/data/models/subscription_model.dart';
import '../../../features/teacher/data/models/purchase_model.dart';

class DatabaseService {
  const DatabaseService();

  // ─── USER ────────────────────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    await Hive.box(HiveBoxes.users).put(user.id, user);
  }

  UserModel? getUser(String userId) {
    return Hive.box(HiveBoxes.users).get(userId) as UserModel?;
  }

  List<UserModel> getAllUsers() {
    return Hive.box(HiveBoxes.users).values.cast<UserModel>().toList();
  }

  Future<void> deleteUser(String userId) async {
    await Hive.box(HiveBoxes.users).delete(userId);
  }

  // ─── SESSION ─────────────────────────────────────────────────────────
  Future<void> saveSession(SessionModel session) async {
    await Hive.box(HiveBoxes.sessions).put('current', session);
  }

  SessionModel? getCurrentSession() {
    return Hive.box(HiveBoxes.sessions).get('current') as SessionModel?;
  }

  Future<void> clearSession() async {
    await Hive.box(HiveBoxes.sessions).delete('current');
  }

  bool get hasActiveSession {
    final session = getCurrentSession();
    return session != null && !session.isExpired;
  }

  // ─── MARKETPLACE ITEMS ───────────────────────────────────────────────
  Future<void> saveMarketplaceItem(MarketplaceItemModel item) async {
    await Hive.box(HiveBoxes.marketplace).put(item.id, item);
  }

  Future<void> saveAllMarketplaceItems(List<MarketplaceItemModel> items) async {
    final box = Hive.box(HiveBoxes.marketplace);
    final map = {for (final i in items) i.id: i};
    await box.putAll(map);
  }

  MarketplaceItemModel? getMarketplaceItem(String id) {
    return Hive.box(HiveBoxes.marketplace).get(id) as MarketplaceItemModel?;
  }

  List<MarketplaceItemModel> getAllMarketplaceItems() {
    return Hive.box(HiveBoxes.marketplace)
        .values
        .cast<MarketplaceItemModel>()
        .toList();
  }

  List<MarketplaceItemModel> getDownloadedItems() {
    return getAllMarketplaceItems().where((i) => i.isDownloaded).toList();
  }

  List<MarketplaceItemModel> getTeacherPublishedItems(String teacherId) {
    return getAllMarketplaceItems()
        .where((i) => i.authorId == teacherId)
        .toList();
  }

  List<MarketplaceItemModel> filterItems({
    String? subject,
    String? gradeLevel,
    String? type,
  }) {
    return getAllMarketplaceItems().where((i) {
      if (subject != null && i.subject != subject) return false;
      if (gradeLevel != null && i.gradeLevel != gradeLevel) return false;
      if (type != null && i.type != type) return false;
      return true;
    }).toList();
  }

  // ─── PROGRESS ────────────────────────────────────────────────────────
  Future<void> saveProgress(ProgressModel progress) async {
    await Hive.box(HiveBoxes.progress).put(progress.id, progress);
  }

  ProgressModel? getProgress(String userId, String lessonId) {
    return Hive.box(HiveBoxes.progress).get('${userId}_$lessonId')
        as ProgressModel?;
  }

  List<ProgressModel> getUserProgress(String userId) {
    return Hive.box(HiveBoxes.progress)
        .values
        .cast<ProgressModel>()
        .where((p) => p.userId == userId)
        .toList();
  }

  List<ProgressModel> getCompletedLessons(String userId) {
    return getUserProgress(userId).where((p) => p.isCompleted).toList();
  }

  // ─── GAMIFICATION ────────────────────────────────────────────────────
  Future<void> saveGamification(GamificationModel g) async {
    await Hive.box(HiveBoxes.gamification).put(g.userId, g);
  }

  GamificationModel getOrCreateGamification(String userId) {
    final existing = Hive.box(HiveBoxes.gamification).get(userId);
    return (existing as GamificationModel?) ?? GamificationModel.empty(userId);
  }

  Future<GamificationModel> addXp(String userId, int xp, {String? subject}) async {
    final current = getOrCreateGamification(userId);
    final updated = current.addXp(xp, subject: subject).updateStreak();
    await saveGamification(updated);
    return updated;
  }

  Future<GamificationModel> unlockBadge(String userId, String badgeId) async {
    final current = getOrCreateGamification(userId);
    if (current.unlockedBadgeIds.contains(badgeId)) return current;
    final updated = current.copyWith(
      unlockedBadgeIds: [...current.unlockedBadgeIds, badgeId],
    );
    await saveGamification(updated);
    return updated;
  }

  List<GamificationModel> getLeaderboard() {
    return Hive.box(HiveBoxes.gamification)
        .values
        .whereType<GamificationModel>()
        .toList()
      ..sort((a, b) => b.totalXp.compareTo(a.totalXp));
  }

  // ─── BADGES ──────────────────────────────────────────────────────────
  Future<void> saveAllBadges(List<BadgeModel> badges) async {
    final box = Hive.box(HiveBoxes.gamification);
    for (final b in badges) {
      await box.put('badge_${b.id}', b);
    }
  }

  List<BadgeModel> getAllBadges() {
    return Hive.box(HiveBoxes.gamification)
        .values
        .whereType<BadgeModel>()
        .toList();
  }

  // ─── AI CACHE ────────────────────────────────────────────────────────
  Future<void> saveAiCache(AiCacheEntryModel entry) async {
    await Hive.box(HiveBoxes.aiCache).put(entry.queryHash, entry);
  }

  AiCacheEntryModel? getAiCache(String queryHash) {
    return Hive.box(HiveBoxes.aiCache).get(queryHash) as AiCacheEntryModel?;
  }

  Future<void> pruneExpiredAiCache(int maxAgeHours) async {
    final box = Hive.box(HiveBoxes.aiCache);
    final expiredKeys = box.keys.where((k) {
      final entry = box.get(k) as AiCacheEntryModel?;
      return entry?.isExpired(maxAgeHours) ?? true;
    }).toList();
    await box.deleteAll(expiredKeys);
  }

  // ─── SYNC QUEUE ──────────────────────────────────────────────────────
  Future<void> enqueueSyncAction({
    required String type,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final action = SyncActionModel(
      id: const Uuid().v4(),
      type: type,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now().toIso8601String(),
    );
    await Hive.box(HiveBoxes.syncQueue).put(action.id, action);
  }

  List<SyncActionModel> getPendingSyncActions() {
    return Hive.box(HiveBoxes.syncQueue)
        .values
        .cast<SyncActionModel>()
        .where((a) => a.isPending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> updateSyncAction(SyncActionModel action) async {
    await Hive.box(HiveBoxes.syncQueue).put(action.id, action);
  }

  Future<void> removeDoneSyncActions() async {
    final box = Hive.box(HiveBoxes.syncQueue);
    final doneKeys = box.keys.where((k) {
      final a = box.get(k) as SyncActionModel?;
      return a?.isDone ?? false;
    }).toList();
    await box.deleteAll(doneKeys);
  }

  int get pendingSyncCount => getPendingSyncActions().length;

  // ─── SETTINGS ────────────────────────────────────────────────────────
  Future<void> saveSettings(SettingsModel settings) async {
    await Hive.box(HiveBoxes.settings).put(settings.userId, settings);
  }

  SettingsModel getSettings(String userId) {
    final stored = Hive.box(HiveBoxes.settings).get(userId);
    return (stored as SettingsModel?) ?? SettingsModel.defaults(userId);
  }

  // ─── CLASSROOM ───────────────────────────────────────────────────────
  Future<void> saveClassroom(ClassroomModel classroom) async {
    await Hive.box(HiveBoxes.classroom).put(classroom.id, classroom);
  }

  ClassroomModel? getActiveClassroom(String teacherId) {
    return Hive.box(HiveBoxes.classroom)
        .values
        .cast<ClassroomModel>()
        .where((c) => c.teacherId == teacherId && c.isActive)
        .firstOrNull;
  }

  // ─── SUBSCRIPTIONS ───────────────────────────────────────────────────
  Future<void> saveSubscription(SubscriptionModel sub) async {
    await Hive.box(HiveBoxes.subscriptions).put(sub.userId, sub);
  }

  SubscriptionModel? getSubscription(String userId) {
    return Hive.box(HiveBoxes.subscriptions).get(userId) as SubscriptionModel?;
  }

  bool hasActiveSubscription(String userId) {
    return getSubscription(userId)?.isValid ?? false;
  }

  // ─── PURCHASES ───────────────────────────────────────────────────────
  Future<void> savePurchase(PurchaseModel purchase) async {
    await Hive.box(HiveBoxes.purchases).put(purchase.id, purchase);
  }

  List<PurchaseModel> getUserPurchases(String userId) {
    return Hive.box(HiveBoxes.purchases)
        .values
        .whereType<PurchaseModel>()
        .where((p) => p.userId == userId)
        .toList();
  }

  List<PurchaseModel> getTeacherRevenue(String teacherId) {
    return Hive.box(HiveBoxes.purchases)
        .values
        .whereType<PurchaseModel>()
        .where((p) => p.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  bool hasPurchased(String userId, String contentId) {
    return Hive.box(HiveBoxes.purchases)
        .values
        .whereType<PurchaseModel>()
        .any((p) => p.userId == userId && p.contentId == contentId);
  }

  int teacherTotalEarnings(String teacherId) {
    return getTeacherRevenue(teacherId).fold(0, (s, p) => s + p.priceFcfa);
  }

  // ─── GLOBAL UTILS ────────────────────────────────────────────────────
  int get downloadedContentSizeBytes {
    return getDownloadedItems().fold(0, (sum, i) => sum + i.fileSizeBytes);
  }

  Future<void> clearUserData(String userId) async {
    await clearSession();
    final box = Hive.box(HiveBoxes.gamification);
    await box.delete(userId);
  }

  Future<void> clearAll() async {
    for (final boxName in [
      HiveBoxes.users, HiveBoxes.sessions, HiveBoxes.contents,
      HiveBoxes.progress, HiveBoxes.gamification, HiveBoxes.syncQueue,
      HiveBoxes.aiCache, HiveBoxes.settings, HiveBoxes.orientation,
      HiveBoxes.classroom, HiveBoxes.marketplace,
      HiveBoxes.subscriptions, HiveBoxes.purchases,
    ]) {
      await Hive.box(boxName).clear();
    }
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return const DatabaseService();
});
