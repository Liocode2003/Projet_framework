import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
      icon: Icons.school_rounded,
      emoji: '📚',
      colors: [Color(0xFF1A0A3E), AppColors.primaryDark, AppColors.primary],
      title: 'Apprends sans internet',
      body:
          'Tous tes cours APC disponibles hors ligne. Télécharge une fois, apprends partout — en classe, à la maison, au village.',
    ),
    _Slide(
      icon: Icons.psychology_rounded,
      emoji: '🤖',
      colors: [Color(0xFF3D0030), Color(0xFF8B0050), AppColors.pink],
      title: 'Ton tuteur IA',
      body:
          'Pose tes questions à l\'assistant intelligent. Il te guide pas à pas, avec voix et explications personnalisées.',
    ),
    _Slide(
      icon: Icons.emoji_events_rounded,
      emoji: '🏆',
      colors: [Color(0xFF3D2A00), Color(0xFF8B6000), AppColors.gold],
      title: 'Joue et progresse',
      body:
          'Gagne des XP, débloque des badges, grimpe au classement. L\'apprentissage devient une aventure passionnante.',
    ),
    _Slide(
      icon: Icons.wifi_rounded,
      emoji: '📡',
      colors: [Color(0xFF003D35), Color(0xFF006B60), AppColors.teal],
      title: 'Classe sans réseau',
      body:
          'L\'enseignant partage ses cours via Wi-Fi local. Les élèves reçoivent tout instantanément — zéro réseau mobile.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Skip ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator dots
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Passer',
                        style: TextStyle(fontFamily: 'Nunito')),
                  ),
                ],
              ),
            ),

            // ── PageView ──────────────────────────────────────────────────
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

            // ── CTA Button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _current == _slides.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: TextStyle(
                          color: slide.colors.last,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _current == _slides.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: slide.colors.last,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          // Animated icon with emoji
          ScaleTransition(
            scale: CurvedAnimation(
              parent: iconController,
              curve: Curves.elasticOut,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                // Inner circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Text(slide.emoji,
                        style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 44),

          Text(
            slide.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            slide.body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String emoji;
  final List<Color> colors;
  final String title;
  final String body;

  const _Slide({
    required this.icon,
    required this.emoji,
    required this.colors,
    required this.title,
    required this.body,
  });
}
