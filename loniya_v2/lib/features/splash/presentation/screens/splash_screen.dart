import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _ringController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _ringAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _ringAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _navigate(AuthState authState) {
    if (_navigated || !mounted) return;
    if (authState.status == AuthStatus.initial) return;
    _navigated = true;

    if (!_hasSeenOnboarding()) {
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
    ref.listen<AuthState>(authNotifierProvider, (_, next) async {
      if (next.status != AuthStatus.initial) {
        await Future.delayed(const Duration(milliseconds: 1800));
        _navigate(next);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authNotifierProvider);
      if (auth.status != AuthStatus.initial) {
        await Future.delayed(const Duration(milliseconds: 1800));
        _navigate(auth);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C0A1E),
              Color(0xFF1A0A3E),
              Color(0xFF0C0A1E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative circles ──────────────────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withOpacity(0.06),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing rings + logo
                    AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (_, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _Ring(
                              scale: 1.0 + _ringAnim.value * 0.6,
                              opacity: (1 - _ringAnim.value) * 0.25,
                              color: AppColors.primary,
                              baseSize: 130,
                            ),
                            _Ring(
                              scale: 1.0 + ((_ringAnim.value + 0.35) % 1.0) * 0.6,
                              opacity: (1 - ((_ringAnim.value + 0.35) % 1.0)) * 0.15,
                              color: AppColors.primaryLight,
                              baseSize: 130,
                            ),
                            child!,
                          ],
                        );
                      },
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 32,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'L',
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // LONIYA
                    const Text(
                      'LONIYA',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.tealLight, AppColors.primaryLight],
                      ).createShader(bounds),
                      child: const Text(
                        'Apprendre partout, tout le temps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 72),

                    // Loader
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double scale;
  final double opacity;
  final Color color;
  final double baseSize;

  const _Ring({
    required this.scale,
    required this.opacity,
    required this.color,
    required this.baseSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = baseSize * scale;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
