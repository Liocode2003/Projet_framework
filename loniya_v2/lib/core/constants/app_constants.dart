/// Constantes globales de l'application yikri
class AppConstants {
  AppConstants._();

  // ── App info ──────────────────────────────────────────────────────────
  static const String appName    = 'yikri';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Apprendre partout · Progresser toujours';
  static const String appSlogan  = 'Le savoir, partout au Burkina';

  // ── Économie crédits ──────────────────────────────────────────────────
  static const int creditBase              = 20;  // bienvenue, jamais déduits
  static const int creditBonusCap          = 60;  // plafond cumulatif bonus
  static const int creditPerGame           = 2;   // par niveau de jeu
  static const int creditPerChallenge      = 5;   // défi Le Sage réussi
  static const int creditPerPerfectQcm     = 3;   // QCM parfait
  static const int creditPerStreak3days    = 3;   // série 3 jours
  static const int creditPerStreak7days    = 10;  // série 7 jours
  static const int creditUnlockThreshold   = 30;  // cumulatif → déblocage remises
  static const int creditPerSprint         = 3;   // sprint 60s réussi

  // Niveaux crédits
  static const int levelEruditThreshold   = 30;  // Apprenti → Érudit
  static const int levelSageThreshold     = 80;  // Érudit → Sage

  // Seuils d'utilisation crédits (bonus seulement)
  static const int creditThreshold50      = 20;  // 20 crédits → -50% (100 FCFA)
  static const int creditThresholdFree    = 40;  // 40 crédits → gratuit

  // ── Prix (FCFA) ───────────────────────────────────────────────────────
  static const int coursePrice          = 200;  // prix unique tous cours
  static const int coursePriceDiscount  = 100;  // après 20 crédits
  static const int coursePriceFree      = 0;    // après 40 crédits
  static const int teacherSubAnnual     = 2000; // abonnement enseignant/an

  // ── Codes format ──────────────────────────────────────────────────────
  static const String classCodePrefix   = 'CL';   // CL-XXX-000
  static const String parentCodePrefix  = 'YK';   // YK-XXXX-BF
  static const String teacherCodePrefix = 'PROF'; // PROF-XX-XXXX
  static const int parentCodeExpiryHours = 24;

  // ── Opérateurs mobile money ───────────────────────────────────────────
  static const List<String> mobileMoneyOperators = [
    'Orange Money',
    'Moov Money',
    'Telecel Money',
    'Sank Money',
  ];

  // ── Classes (programme burkinabè) ─────────────────────────────────────
  static const List<String> studentGrades = [
    'CP1', 'CP2', 'CE1', 'CE2', 'CM1', 'CM2',
    '6ème', '5ème', '4ème', '3ème',
    '2nde A', '2nde B', '2nde C', '2nde D',
    '1ère A', '1ère B', '1ère C', '1ère D',
    'Tle A', 'Tle B', 'Tle C', 'Tle D',
  ];

  // Classes éligibles orientation
  static const List<String> orientationGrades = ['3ème', 'Tle A', 'Tle B', 'Tle C', 'Tle D'];

  // ── Matières (programme burkinabè) ────────────────────────────────────
  static const List<String> subjects = [
    'Mathématiques',
    'Physique-Chimie',
    'Sciences de la Vie et de la Terre',
    'Français',
    'Histoire-Géographie',
    'Anglais',
    'Philosophie',
    'Éducation Civique',
    'Éducation Physique',
    'Informatique',
    'Comptabilité',
    'Économie',
  ];

  // ── Filières d'orientation ────────────────────────────────────────────
  static const List<String> orientationInterests = [
    'Sciences exactes', 'Médecine / Santé', 'Ingénierie',
    'Commerce / Gestion', 'Littérature / Arts', 'Droit',
    'Informatique', 'Agriculture / Agronomie', 'Éducation',
  ];

  // ── Le Sage ───────────────────────────────────────────────────────────
  static const String sageName           = 'Le Sage';
  static const String sageGreeting       = 'Bonjour ! Je suis Le Sage 🌿\nPose-moi une question, je te guiderai vers la réponse.';
  static const int    sageCacheHours     = 72;
  static const int    sageMaxHistory     = 12;
  static const int    aiCacheExpiryHours = 72;   // durée cache réponses IA
  static const int    maxCachedImages    = 100;  // quota images en cache

  // ── Auth / OTP ────────────────────────────────────────────────────────
  static const String mockOtpCode = '1234';  // code OTP mode démo

  // ── Réseau local (Classe Connectée) ──────────────────────────────────
  static const int    localServerPort  = 8080;
  static const String mdnsServiceType  = '_yikri._tcp';
  static const String mdnsServiceName  = 'yikri-classroom';
  static const int    localNetworkTimeout = 30;

  // ── Sync ──────────────────────────────────────────────────────────────
  static const int maxSyncRetries        = 3;
  static const int syncRetryDelaySeconds = 10;

  // ── Gamification ──────────────────────────────────────────────────────
  static const int totalBadges      = 18;
  static const int maxLevel         = 100;
  static const int streakResetHours = 48;
  static const int xpPerLesson      = 50;
  static const int xpPerBadge       = 200;

  // ── Auth ──────────────────────────────────────────────────────────────
  static const int    sessionExpiryDays  = 30;
  static const int    minPasswordLength  = 6;
  static const String roleStudent        = 'student';
  static const String roleTeacher        = 'teacher';
  static const String roleParent         = 'parent';

  // ── Apprentissage ─────────────────────────────────────────────────────
  static const int minPassScore     = 60;
  static const int maxStepsPerLesson = 10;

  // ── Anti-abus offline ─────────────────────────────────────────────────
  static const int maxOfflineCreditPerDay  = 6;
  static const int maxOfflineSessionHours  = 8;

  // ── Langues supportées ───────────────────────────────────────────────
  static const List<String> supportedLocales = ['fr', 'bm']; // Français + Mooré/Bambara
}
