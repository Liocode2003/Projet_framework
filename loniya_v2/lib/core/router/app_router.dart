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
import '../../features/home/presentation/screens/home_screen.dart';
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
import '../constants/hive_boxes.dart';
import '../../features/home/presentation/widgets/app_shell.dart';

// Provider for GoRouter instance — available app-wide via Riverpod
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(_checkInitialAuth());

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false, // set true during dev

    // Redirect logic: guards protected routes
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authNotifier.value;
      final isSplash = state.matchedLocation == RouteNames.splash;
      final isOnboarding = state.matchedLocation == RouteNames.onboarding;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // Always allow splash and onboarding
      if (isSplash || isOnboarding) return null;

      // Redirect unauthenticated users to phone auth
      if (!isAuthenticated && !isAuthRoute) {
        return RouteNames.authPhone;
      }

      // Redirect authenticated users away from auth screens
      if (isAuthenticated && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },

    routes: [
      // ─── Splash ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const SplashScreen(),
        ),
      ),

      // ─── Onboarding ───────────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // ─── Auth Flow ────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.authPhone,
        name: 'auth-phone',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const AuthPhoneScreen(),
        ),
        routes: [
          GoRoute(
            path: 'otp',
            name: 'auth-otp',
            pageBuilder: (context, state) {
              final phone = state.extra as String? ?? '';
              return _buildPage(
                state: state,
                child: AuthOtpScreen(phone: phone),
              );
            },
          ),
          GoRoute(
            path: 'role',
            name: 'auth-role',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AuthRoleScreen(),
            ),
          ),
          GoRoute(
            path: 'consent',
            name: 'auth-consent',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AuthConsentScreen(),
            ),
          ),
          GoRoute(
            path: 'pin',
            name: 'auth-pin',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AuthPinScreen(),
            ),
          ),
        ],
      ),

      // ─── Main App Shell (with bottom navigation) ──────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Home Dashboard
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),

          // Marketplace
          GoRoute(
            path: RouteNames.marketplace,
            name: 'marketplace',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const MarketplaceScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'marketplace-detail',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _buildPage(
                    state: state,
                    child: MarketplaceDetailScreen(contentId: id),
                  );
                },
              ),
            ],
          ),

          // Learning / APC Engine
          GoRoute(
            path: RouteNames.learning,
            name: 'learning',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const LearningScreen(),
            ),
            routes: [
              GoRoute(
                path: ':lessonId',
                name: 'lesson',
                pageBuilder: (context, state) {
                  final lessonId = state.pathParameters['lessonId']!;
                  return _buildPage(
                    state: state,
                    child: LessonScreen(lessonId: lessonId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'result',
                    name: 'lesson-result',
                    pageBuilder: (context, state) {
                      final lessonId = state.pathParameters['lessonId']!;
                      return _buildPage(
                        state: state,
                        child: LessonResultScreen(lessonId: lessonId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // AI Tutor
          GoRoute(
            path: RouteNames.aiTutor,
            name: 'ai-tutor',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AiTutorScreen(),
            ),
          ),

          // Gamification
          GoRoute(
            path: RouteNames.gamification,
            name: 'gamification',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const GamificationScreen(),
            ),
          ),

          // Orientation
          GoRoute(
            path: RouteNames.orientation,
            name: 'orientation',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const OrientationScreen(),
            ),
            routes: [
              GoRoute(
                path: 'result',
                name: 'orientation-result',
                pageBuilder: (context, state) => _buildPage(
                  state: state,
                  child: const OrientationResultScreen(),
                ),
              ),
            ],
          ),

          // Teacher Dashboard
          GoRoute(
            path: RouteNames.teacherDashboard,
            name: 'teacher',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const TeacherDashboardScreen(),
            ),
          ),

          // Local Classroom
          GoRoute(
            path: RouteNames.localClassroom,
            name: 'local-classroom',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const LocalClassroomScreen(),
            ),
          ),
        ],
      ),
    ],

    // Error page
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page introuvable',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(state.error?.message ?? 'Erreur de navigation'),
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

// ─── Helper: build a page with fade transition (low-end optimized) ───────────
CustomTransitionPage _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 180),
  );
}

// ─── Check initial auth state from Hive ──────────────────────────────────────
bool _checkInitialAuth() {
  // Will be replaced by actual session check in Phase 4 (Auth)
  // For now returns false → redirect to auth flow
  try {
    final box = Hive.box(HiveBoxes.sessions);
    return box.isNotEmpty;
  } catch (_) {
    return false;
  }
}
