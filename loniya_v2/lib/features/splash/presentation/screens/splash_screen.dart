import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(AuthState authState) {
    if (_navigated || !mounted) return;
    if (authState.status == AuthStatus.initial) return; // still loading

    _navigated = true;

    final hasOnboarding = _hasSeenOnboarding();

    if (!hasOnboarding) {
      context.go(RouteNames.onboarding);
    } else if (authState.isAuthenticated) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.authPhone);
    }
  }

  bool _hasSeenOnboarding() {
    try {
      return Hive.box(HiveBoxes.settings)
              .get('onboarding_done', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // When auth state resolves (not initial), navigate after min display time
    ref.listen<AuthState>(authNotifierProvider, (_, next) async {
      if (next.status != AuthStatus.initial) {
        await Future.delayed(const Duration(milliseconds: 1600));
        _navigate(next);
      }
    });

    // Also handle case where state is already resolved on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authNotifierProvider);
      if (auth.status != AuthStatus.initial) {
        await Future.delayed(const Duration(milliseconds: 1600));
        _navigate(auth);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15),
                          blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Center(
                    child: Text('L',
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
                          color: AppColors.primary, fontFamily: 'Nunito')),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('LONIYA',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                      color: Colors.white, fontFamily: 'Nunito', letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('Apprendre partout, tout le temps',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                const SizedBox(height: 64),
                const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
