class RouteNames {
  RouteNames._();

  // Root
  static const String splash    = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String authPhone   = '/auth/phone';
  static const String authOtp     = '/auth/otp';
  static const String authRole    = '/auth/role';
  static const String authConsent = '/auth/consent';
  static const String authPin     = '/auth/pin';
  static const String authProfile = '/auth/profile';

  // Main tabs
  static const String home = '/home';

  // Catalogue (anciennement marketplace)
  static const String marketplace       = '/catalogue';
  static const String marketplaceDetail = '/catalogue/:id';

  // Apprentissage
  static const String learning      = '/learning';
  static const String learningLesson = '/learning/:lessonId';
  static const String learningResult = '/learning/:lessonId/result';
  static const String qcm            = '/learning/:lessonId/qcm';
  static const String performance    = '/learning/performance';

  // Le Sage (anciennement AI Tutor)
  static const String aiTutor = '/le-sage';

  // Gamification & classement
  static const String gamification = '/gamification';
  static const String leaderboard  = '/gamification/leaderboard';

  // Orientation
  static const String orientation       = '/orientation';
  static const String orientationResult = '/orientation/result';

  // Teacher
  static const String teacherDashboard    = '/teacher';
  static const String teacherSubscription = '/teacher/subscription';
  static const String teacherRevenue      = '/teacher/revenue';
  static const String teacherPublish      = '/teacher/publish';

  // Classe Connectée
  static const String localClassroom     = '/classe';
  static const String localClassroomHost = '/classe/host';
  static const String localClassroomJoin = '/classe/join';

  // Devoirs
  static const String homework = '/devoirs';

  // Jeu éducatif
  static const String game      = '/jeu';
  static const String gameSprint = '/jeu/sprint';
  static const String gameSage   = '/jeu/sage';

  // Mode Examen
  static const String examMode = '/examen';

  // Parent
  static const String parentDashboard = '/parent';
  static const String parentLink      = '/parent/lier';

  // Crédits
  static const String credits = '/credits';

  // Settings
  static const String settings      = '/settings';
  static const String accessibility = '/settings/accessibility';

  // Profil
  static const String profile = '/profil';
}
