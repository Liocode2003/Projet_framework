import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_phone_screen.dart';
import '../../features/auth/presentation/screens/auth_otp_screen.dart';
import '../../features/auth/presentation/screens/auth_role_screen.dart';
import '../../features/auth/presentation/screens/auth_consent_screen.dart';
import '../../features/auth/presentation/screens/auth_pin_screen.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/app_shell.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_detail_screen.dart';
import '../../features/learning/presentation/screens/learning_screen.dart';
import '../../features/learning/presentation/screens/lesson_screen.dart';
import '../../features/learning/presentation/screens/lesson_result_screen.dart';
import '../../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../../features/gamification/presentation/screens/gamification_screen.dart';
import '../../features/orientation/presentation/screens/orientation_screen.dart';
import '../../features/orientation/presentation/screens/orientation_result_screen.dart';
import '../../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/local_classroom/presentation/screens/local_classroom_screen.dart';
import '../constants/route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listenable that triggers router refresh when auth state changes
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    refreshListenable: authListenable,

    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;

      final loc = state.matchedLocation;
      final isSplash     = loc == RouteNames.splash;
      final isOnboarding = loc == RouteNames.onboarding;
      final isAuthRoute  = loc.startsWith('/auth');

      // Never redirect while splash is doing its own routing
      if (isSplash) return null;
      // Allow onboarding freely
      if (isOnboarding) return null;
      // Wait for initial session check
      if (isInitial) return RouteNames.splash;

      // Unauthenticated user trying to access app → send to auth
      if (!isAuthenticated && !isAuthRoute) return RouteNames.authPhone;
      // Authenticated user hitting auth screens → send home
      if (isAuthenticated && isAuthRoute) return RouteNames.home;

      return null;
    },

    routes: [
      // ─── Splash ─────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (c, s) => _fade(s, const SplashScreen()),
      ),

      // ─── Onboarding ──────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        pageBuilder: (c, s) => _fade(s, const OnboardingScreen()),
      ),

      // ─── Auth flow ────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.authPhone,
        name: 'auth-phone',
        pageBuilder: (c, s) => _fade(s, const AuthPhoneScreen()),
        routes: [
          GoRoute(
            path: 'otp',
            name: 'auth-otp',
            pageBuilder: (c, s) => _fade(
              s, AuthOtpScreen(phone: s.extra as String? ?? ''),
            ),
          ),
          GoRoute(
            path: 'role',
            name: 'auth-role',
            pageBuilder: (c, s) => _fade(s, const AuthRoleScreen()),
          ),
          GoRoute(
            path: 'consent',
            name: 'auth-consent',
            pageBuilder: (c, s) => _fade(s, const AuthConsentScreen()),
          ),
          GoRoute(
            path: 'pin',
            name: 'auth-pin',
            pageBuilder: (c, s) => _fade(s, const AuthPinScreen()),
          ),
        ],
      ),

      // ─── Main shell (bottom navigation) ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (c, s) => _fade(s, const HomeScreen()),
          ),
          GoRoute(
            path: RouteNames.marketplace,
            name: 'marketplace',
            pageBuilder: (c, s) => _fade(s, const MarketplaceScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'marketplace-detail',
                pageBuilder: (c, s) => _fade(
                  s, MarketplaceDetailScreen(
                      contentId: s.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.learning,
            name: 'learning',
            pageBuilder: (c, s) => _fade(s, const LearningScreen()),
            routes: [
              GoRoute(
                path: ':lessonId',
                name: 'lesson',
                pageBuilder: (c, s) => _fade(
                  s, LessonScreen(
                      lessonId: s.pathParameters['lessonId']!),
                ),
                routes: [
                  GoRoute(
                    path: 'result',
                    name: 'lesson-result',
                    pageBuilder: (c, s) => _fade(
                      s, LessonResultScreen(
                          lessonId: s.pathParameters['lessonId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.aiTutor,
            name: 'ai-tutor',
            pageBuilder: (c, s) => _fade(s, const AiTutorScreen()),
          ),
          GoRoute(
            path: RouteNames.gamification,
            name: 'gamification',
            pageBuilder: (c, s) => _fade(s, const GamificationScreen()),
          ),
          GoRoute(
            path: RouteNames.orientation,
            name: 'orientation',
            pageBuilder: (c, s) => _fade(s, const OrientationScreen()),
            routes: [
              GoRoute(
                path: 'result',
                name: 'orientation-result',
                pageBuilder: (c, s) => _fade(s, const OrientationResultScreen()),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.teacherDashboard,
            name: 'teacher',
            pageBuilder: (c, s) => _fade(s, const TeacherDashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.localClassroom,
            name: 'local-classroom',
            pageBuilder: (c, s) => _fade(s, const LocalClassroomScreen()),
          ),
        ],
      ),
    ],

    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page introuvable',
                style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

// ─── Fade page transition (low-end optimized) ─────────────────────────────────
CustomTransitionPage _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(
          opacity: CurveTween(curve: Curves.easeIn).animate(animation),
          child: child,
        ),
    transitionDuration: const Duration(milliseconds: 180),
  );
}

// ─── Listenable that notifies GoRouter when auth state changes ────────────────
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, __) => notifyListeners());
  }
}
