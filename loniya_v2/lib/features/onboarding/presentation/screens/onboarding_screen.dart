import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _page = PageController();
  late AnimationController _fadeCtrl;
  int _current = 0;

  static const _slides = [
    _Slide(
      emoji: '🌿',
      title: 'Rencontre Le Sage',
      subtitle:
          'Ton professeur IA personnel. Il te guide, te pose des questions et t\'aide à vraiment comprendre — pas juste mémoriser.',
      colors: [Color(0xFF1A3A2A), Color(0xFF2E5239), AppColors.sage],
    ),
    _Slide(
      emoji: '📚',
      title: 'Apprends sans connexion',
      subtitle:
          'Télécharge tes cours et continue d\'apprendre même sans internet. Parfait pour tout le Burkina Faso.',
      colors: [Color(0xFF3A1A06), Color(0xFF7A3A10), AppColors.primary],
    ),
    _Slide(
      emoji: '🏆',
      title: 'Gagne des crédits',
      subtitle:
          'Joue, relève des défis, maintiens ta série quotidienne. Accumule des crédits pour obtenir des cours gratuitement.',
      colors: [Color(0xFF3A2A00), Color(0xFF8B6200), AppColors.gold],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _page.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
    } else {
      context.go(RouteNames.authPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),

          // Dots en haut à gauche
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Skip
                  if (_current < _slides.length - 1)
                    GestureDetector(
                      onTap: () => context.go(RouteNames.authPhone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bouton CTA en bas
          Positioned(
            bottom: 50,
            left: 32,
            right: 32,
            child: GestureDetector(
              onTap: _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _current == _slides.length - 1
                        ? 'Commencer →'
                        : 'Suivant →',
                    style: TextStyle(
                      color: _slides[_current].colors.last,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.colors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 100, 32, 140),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji dans un cercle lumineux
              Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: slide.colors.last.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    slide.emoji,
                    style: TextStyle(fontSize: size.width * 0.18),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontFamily: 'Nunito',
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final String emoji, title, subtitle;
  final List<Color> colors;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
  });
}
