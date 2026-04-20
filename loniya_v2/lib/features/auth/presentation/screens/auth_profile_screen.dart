import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_notifier.dart';

class AuthProfileScreen extends ConsumerStatefulWidget {
  const AuthProfileScreen({super.key});

  @override
  ConsumerState<AuthProfileScreen> createState() => _AuthProfileScreenState();
}

class _AuthProfileScreenState extends ConsumerState<AuthProfileScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  String? _selected;       // grade or subject

  static const _grades = [
    'CP', 'CE1', 'CE2', 'CM1', 'CM2',
    '6ème', '5ème', '4ème', '3ème',
    '2nde', '1ère', 'Terminale',
  ];

  static const _subjects = [
    'Mathématiques', 'Français', 'Sciences de la Vie et de la Terre',
    'Histoire-Géographie', 'Physique-Chimie', 'Anglais',
    'Philosophie', 'Éducation Physique', 'Informatique', 'Autre',
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  String? get _role => ref.read(authNotifierProvider).role;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    await ref
        .read(authNotifierProvider.notifier)
        .saveProfile(fullName, _selected);
    if (mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final role        = _role ?? 'student';
    final isStudent   = role == 'student';
    final isTeacher   = role == 'teacher';
    final isLoading   = ref.watch(
        authNotifierProvider.select((s) => s.isLoading));

    final heroGradient = isTeacher
        ? const [Color(0xFF003D35), AppColors.teal]
        : isStudent
            ? const [Color(0xFF1A0A3E), AppColors.primary]
            : const [Color(0xFF3D1A00), AppColors.accent];

    final heroIcon = isTeacher
        ? Icons.cast_for_education_rounded
        : isStudent
            ? Icons.school_rounded
            : Icons.family_restroom_rounded;

    final roleLabel = isTeacher
        ? 'Enseignant'
        : isStudent
            ? 'Élève'
            : 'Parent';

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // ── Gradient hero ──────────────────────────────────────────────
          Container(
            height: size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: heroGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(heroIcon, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Profil $roleLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personnalise ton expérience LONIYA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card form ────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tes informations',
                          style: AppTextStyles.headlineSmall
                              .copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),

                      // Prénom
                      TextFormField(
                        controller: _firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),

                      // Nom
                      TextFormField(
                        controller: _lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nom de famille',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),

                      // Grade (student) or Subject (teacher)
                      if (isStudent || isTeacher) ...[
                        Text(
                          isStudent ? 'Classe' : 'Matière enseignée',
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (isStudent ? _grades : _subjects)
                              .map((item) {
                            final sel = _selected == item;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.outline,
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_selected == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              isStudent
                                  ? 'Sélectionne ta classe'
                                  : 'Sélectionne ta matière',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 28),
                      AppButton(
                        label: 'Commencer',
                        prefixIcon: Icons.rocket_launch_rounded,
                        isLoading: isLoading,
                        onPressed: (isStudent || isTeacher) && _selected == null
                            ? null
                            : _submit,
                      ),
                    ],
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
