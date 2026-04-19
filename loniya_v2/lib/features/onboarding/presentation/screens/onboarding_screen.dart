import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pages = PageController();
  late AnimationController _iconController;
  int _current = 0;

  static const _slides = [
    _Slide(
      icon:     Icons.school_rounded,
      gradient: [AppColors.primary, AppColors.primaryDark],
      title:    'Apprends sans internet',
      body:
          'Tous tes cours APC sont disponibles hors ligne. Télécharge une fois et apprends partout — en classe, à la maison, au village.',
    ),
    _Slide(
      icon:     Icons.psychology_rounded,
      gradient: [AppColors.aiTutor, Color(0xFF4A0072)],
      title:    'Ton tuteur IA personnel',
      body:
          'Pose tes questions à l\'assistant intelligent. Il te guide étape par étape sans jamais donner les réponses directement.',
    ),
    _Slide(
      icon:     Icons.emoji_events_rounded,
      gradient: [AppColors.gamification, Color(0xFFBF360C)],
      title:    'Joue et progresse',
      body:
          'Gagne des XP, débloque des badges et monte en niveau chaque jour. L\'apprentissage devient une aventure.',
    ),
    _Slide(
      icon:     Icons.wifi_rounded,
      gradient: [AppColors.localNetwork, Color(0xFF1A237E)],
      title:    'Classe sans internet',
      body:
          'L\'enseignant partage ses cours via Wi-Fi local. Les élèves reçoivent tout instantanément — pas besoin de réseau mobile.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pages.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
    _iconController
      ..reset()
      ..forward();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await Hive.box(HiveBoxes.settings).put('onboarding_done', true);
    if (!mounted) return;
    context.go(RouteNames.authPhone);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Skip ────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Passer'),
                ),
              ),
            ),

            // ── PageView ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pages,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (ctx, i) => _SlideContent(
                  slide: _slides[i],
                  iconController: _iconController,
                  isActive: i == _current,
                ),
              ),
            ),

            // ── Dots ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // ── CTA ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                label: _current == _slides.length - 1
                    ? 'Commencer'
                    : 'Suivant',
                prefixIcon: _current == _slides.length - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                backgroundColor: Colors.white,
                foregroundColor: slide.gradient.first,
                onPressed: _next,
              ),
            ),

            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _Slide slide;
  final AnimationController iconController;
  final bool isActive;

  const _SlideContent({
    required this.slide,
    required this.iconController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          ScaleTransition(
            scale: CurvedAnimation(
              parent: iconController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, size: 64, color: Colors.white),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
  });
}
