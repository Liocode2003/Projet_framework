class RouteNames {
  RouteNames._();

  // Root
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String authPhone = '/auth/phone';
  static const String authOtp = '/auth/otp';
  static const String authRole = '/auth/role';
  static const String authConsent = '/auth/consent';
  static const String authPin = '/auth/pin';

  // Main
  static const String home = '/home';

  // Marketplace
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/:id';

  // Learning
  static const String learning = '/learning';
  static const String learningLesson = '/learning/:lessonId';
  static const String learningResult = '/learning/:lessonId/result';
  static const String qcm = '/learning/:lessonId/qcm';
  static const String performance = '/learning/performance';

  // AI Tutor
  static const String aiTutor = '/ai-tutor';

  // Gamification
  static const String gamification = '/gamification';
  static const String leaderboard = '/gamification/leaderboard';

  // Orientation
  static const String orientation = '/orientation';
  static const String orientationResult = '/orientation/result';

  // Teacher
  static const String teacherDashboard = '/teacher';
  static const String teacherSubscription = '/teacher/subscription';
  static const String teacherRevenue = '/teacher/revenue';

  // Local Classroom
  static const String localClassroom = '/local-classroom';
  static const String localClassroomHost = '/local-classroom/host';
  static const String localClassroomJoin = '/local-classroom/join';

  // Settings
  static const String settings = '/settings';
  static const String accessibility = '/settings/accessibility';

  // Parent
  static const String parentDashboard = '/parent';
}
