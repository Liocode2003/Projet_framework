// Named routes for GoRouter

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
  static const String marketplaceDownload = '/marketplace/:id/download';

  // Learning
  static const String learning = '/learning';
  static const String learningLesson = '/learning/:lessonId';
  static const String learningStep = '/learning/:lessonId/step/:stepIndex';
  static const String learningResult = '/learning/:lessonId/result';

  // AI Tutor
  static const String aiTutor = '/ai-tutor';

  // Gamification
  static const String gamification = '/gamification';
  static const String badges = '/gamification/badges';
  static const String missions = '/gamification/missions';
  static const String leaderboard = '/gamification/leaderboard';

  // Orientation
  static const String orientation = '/orientation';
  static const String orientationResult = '/orientation/result';
  static const String orientationReport = '/orientation/report';

  // Teacher
  static const String teacherDashboard = '/teacher';
  static const String teacherClassroom = '/teacher/classroom';
  static const String teacherStudents = '/teacher/students';
  static const String teacherContent = '/teacher/content';

  // Local Classroom
  static const String localClassroom = '/local-classroom';
  static const String localClassroomHost = '/local-classroom/host';
  static const String localClassroomJoin = '/local-classroom/join';

  // Settings
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsLanguage = '/settings/language';
}
