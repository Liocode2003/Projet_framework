// Hive box names — centralized to avoid typos

class HiveBoxes {
  HiveBoxes._();

  // Encrypted boxes (AES-256)
  static const String users = 'users';
  static const String sessions = 'sessions';
  static const String contents = 'contents';
  static const String progress = 'progress';

  // Non-encrypted boxes
  static const String gamification = 'gamification';
  static const String syncQueue    = 'sync_queue';
  static const String aiCache      = 'ai_cache';
  static const String settings     = 'settings';
  static const String orientation  = 'orientation';
  static const String classroom    = 'classroom';
  static const String marketplace  = 'marketplace';
  static const String subscriptions = 'subscriptions';
  static const String purchases    = 'purchases';
  static const String credits      = 'credits';
  static const String exams        = 'exams';
  static const String homework     = 'homework';
}

// Hive type IDs — must be unique across all models
class HiveTypeIds {
  HiveTypeIds._();

  static const int userModel = 0;
  static const int sessionModel = 1;
  static const int contentModel = 2;
  static const int progressModel = 3;
  static const int gamificationModel = 4;
  static const int syncActionModel = 5;
  static const int aiCacheEntryModel = 6;
  static const int settingsModel = 7;
  static const int orientationResultModel = 8;
  static const int classroomModel = 9;
  static const int badgeModel = 10;
  static const int marketplaceItemModel = 11;
  static const int lessonModel = 12;
  static const int stepModel = 13;
  static const int subscriptionModel = 14;
  static const int purchaseModel = 15;
  static const int creditModel = 20;
  static const int examModeModel = 21;
  static const int homeworkModel = 22;
}
