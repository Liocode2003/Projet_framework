import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _logoScale   = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide   = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _pulse       = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl.forward().then((_) => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final status = ref.read(authNotifierProvider).status;
    if (status == AuthStatus.authenticated) {
      context.go(RouteNames.home);
    } else if (status == AuthStatus.initial) {
      Future.delayed(const Duration(milliseconds: 500), _navigate);
    } else {
      context.go(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Anneaux pulsants en fond
          ...List.generate(3, _buildRing),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo animé
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) => Transform.scale(
                        scale: _pulse.value,
                        child: child,
                      ),
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 48,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'y',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(children: [
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConstants.appTagline,
                          style: TextStyle(
                            color: AppColors.primaryLight.withOpacity(0.85),
                            fontSize: 13,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bas de page
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Column(children: [
                SizedBox(
                  width: 48,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Burkina Faso · Le savoir pour tous',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontFamily: 'Nunito',
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(int index) {
    final size = 180.0 + index * 130;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Center(
        child: Opacity(
          opacity: (0.05 - index * 0.012).clamp(0.0, 1.0),
          child: Container(
            width: size * _pulse.value,
            height: size * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
