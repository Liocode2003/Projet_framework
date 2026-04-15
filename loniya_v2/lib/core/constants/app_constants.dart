// Application-wide constants for LONIYA V2

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'LONIYA V2';
  static const String appVersion = '2.0.0';
  static const String appTagline = 'Apprendre partout, tout le temps';

  // Local network
  static const int localServerPort = 8080;
  static const String mdnsServiceType = '_loniya._tcp';
  static const String mdnsServiceName = 'loniya-classroom';
  static const int localNetworkTimeout = 30; // seconds

  // Sync
  static const int maxSyncRetries = 3;
  static const int syncRetryDelaySeconds = 10;

  // AI Tutor
  static const int aiMaxResponseSentences = 3;
  static const int aiCacheExpiryHours = 24;

  // Gamification
  static const int maxLevel = 100;
  static const int streakResetHours = 48;
  static const int xpPerLesson = 50;
  static const int xpPerDailyMission = 100;
  static const int xpPerBadge = 200;

  // Auth
  static const String mockOtpCode = '1234';
  static const int sessionExpiryDays = 30;
  static const int maxPinAttempts = 5;

  // Learning
  static const int minPassScore = 60; // percentage
  static const int maxStepsPerLesson = 10;

  // Performance
  static const int maxCachedImages = 50;
  static const int maxHiveBoxSize = 1000; // entries
  static const int contentCacheExpiryDays = 7;

  // Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleParent = 'parent';

  // Languages supported
  static const List<String> supportedLocales = ['fr', 'bm']; // French + Bambara
}
