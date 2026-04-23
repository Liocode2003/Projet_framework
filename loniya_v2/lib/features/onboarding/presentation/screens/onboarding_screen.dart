import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';

// ── Onboarding state ─────────────────────────────────────────────────────────

enum _OnboardingStep { roleSelection, registration, avatar }

class _OnboardingData {
  final String? role;
  final String? name;
  final String? phone;
  final String? password;
  final String? grade;
  final int avatarIndex;

  const _OnboardingData({
    this.role,
    this.name,
    this.phone,
    this.password,
    this.grade,
    this.avatarIndex = 0,
  });

  _OnboardingData copyWith({
    String? role,
    String? name,
    String? phone,
    String? password,
    String? grade,
    int? avatarIndex,
  }) => _OnboardingData(
    role: role ?? this.role,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    grade: grade ?? this.grade,
    avatarIndex: avatarIndex ?? this.avatarIndex,
  );
}

// ── Main screen ──────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  _OnboardingStep _step = _OnboardingStep.roleSelection;
  _OnboardingData _data = const _OnboardingData();

  late final AnimationController _sageCtrl;
  late final Animation<double> _sageScale;

  @override
  void initState() {
    super.initState();
    _sageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _sageScale = CurvedAnimation(parent: _sageCtrl, curve: Curves.elasticOut);
    _sageCtrl.forward();
  }

  @override
  void dispose() {
    _sageCtrl.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _data = _data.copyWith(role: role);
      _step = _OnboardingStep.registration;
    });
    _sageCtrl.reset();
    _sageCtrl.forward();
  }

  void _submitRegistration(_OnboardingData updated) {
    setState(() {
      _data = updated;
      _step = _OnboardingStep.avatar;
    });
    _sageCtrl.reset();
    _sageCtrl.forward();
  }

  void _selectAvatar(int index) {
    setState(() => _data = _data.copyWith(avatarIndex: index));
  }

  void _finish() => context.go(RouteNames.authPhone);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SageHeader(sageScale: _sageScale, step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: switch (_step) {
                  _OnboardingStep.roleSelection => _RoleStep(
                      key: const ValueKey('role'),
                      onSelect: _selectRole,
                    ),
                  _OnboardingStep.registration => _RegistrationStep(
                      key: const ValueKey('reg'),
                      data: _data,
                      onSubmit: _submitRegistration,
                    ),
                  _OnboardingStep.avatar => _AvatarStep(
                      key: const ValueKey('avatar'),
                      data: _data,
                      onSelect: _selectAvatar,
                      onFinish: _finish,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Le Sage Header ───────────────────────────────────────────────────────────

class _SageHeader extends StatelessWidget {
  final Animation<double> sageScale;
  final _OnboardingStep step;

  const _SageHeader({required this.sageScale, required this.step});

  String get _message => switch (step) {
    _OnboardingStep.roleSelection =>
      'Bonjour ! Je suis ${AppConstants.sageName} 🌿\nQui es-tu ?',
    _OnboardingStep.registration =>
      'Parfait ! Dis-moi comment tu t\'appelles\net crée ton compte.',
    _OnboardingStep.avatar =>
      'Excellent ! Choisis ton avatar\npour commencer l\'aventure yikri !',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A2A), Color(0xFF2E5239), AppColors.sage],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: sageScale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sage.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                _message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Role Selection ───────────────────────────────────────────────────

class _RoleStep extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _RoleStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          const Text(
            'Je suis...',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          _RoleCard(
            emoji: '🎒',
            title: 'Élève',
            subtitle: 'J\'apprends et progresse avec Le Sage',
            color: AppColors.primary,
            onTap: () => onSelect(AppConstants.roleStudent),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            emoji: '📖',
            title: 'Enseignant',
            subtitle: 'Je crée des cours et suis mes élèves',
            color: AppColors.sage,
            onTap: () => onSelect(AppConstants.roleTeacher),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            emoji: '👨‍👩‍👧',
            title: 'Parent',
            subtitle: 'Je surveille les progrès de mon enfant',
            color: AppColors.accent,
            onTap: () => onSelect(AppConstants.roleParent),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Registration ─────────────────────────────────────────────────────

class _RegistrationStep extends StatefulWidget {
  final _OnboardingData data;
  final ValueChanged<_OnboardingData> onSubmit;

  const _RegistrationStep({
    super.key,
    required this.data,
    required this.onSubmit,
  });

  @override
  State<_RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends State<_RegistrationStep> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  String? _selectedGrade;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.data.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.data.phone ?? '');
    _passCtrl  = TextEditingController(text: widget.data.password ?? '');
    _selectedGrade = widget.data.grade;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(widget.data.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
      grade: _selectedGrade,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.data.role == AppConstants.roleStudent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stepTitle(widget.data.role),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Prénom et nom',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (v.trim().length < 2) return 'Trop court';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+226 XX XX XX XX',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (v.trim().length < 8) return 'Numéro invalide';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < AppConstants.minPasswordLength) {
                  return 'Minimum ${AppConstants.minPasswordLength} caractères';
                }
                return null;
              },
            ),

            if (isStudent) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Ma classe',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: AppConstants.studentGrades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGrade = v),
                validator: (v) => v == null ? 'Choisis ta classe' : null,
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continuer →',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(String? role) => switch (role) {
    AppConstants.roleTeacher => 'Crée ton compte enseignant',
    AppConstants.roleParent  => 'Crée ton compte parent',
    _                        => 'Crée ton compte élève',
  };
}

// ── Step 3: Avatar Selection ─────────────────────────────────────────────────

class _AvatarStep extends StatefulWidget {
  final _OnboardingData data;
  final ValueChanged<int> onSelect;
  final VoidCallback onFinish;

  const _AvatarStep({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onFinish,
  });

  @override
  State<_AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends State<_AvatarStep> {
  int _selected = 0;

  static const _avatars = ['🦁', '🐘', '🦊', '🦅', '🐆', '🦋'];
  static const _avatarColors = [
    Color(0xFFCC7722), Color(0xFF4A7C59), Color(0xFFD64B2A),
    Color(0xFF1A6B8A), Color(0xFF8A4A1A), Color(0xFF6B1A8A),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = (widget.data.name ?? 'toi').split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          Text(
            'Bravo $firstName ! 🎉',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ton parcours commence ici.\nAccumule des crédits, progresse et deviens Sage !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                '+${AppConstants.creditBase} crédits de bienvenue !',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          const Text(
            'Choisis ton avatar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(_avatars.length, (i) {
                final isSelected = i == _selected;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = i);
                    widget.onSelect(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _avatarColors[i].withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? _avatarColors[i]
                            : AppColors.surfaceVariant,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(
                              color: _avatarColors[i].withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _avatars[i],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onFinish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Commencer l\'aventure !',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
