import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class ParentLinkScreen extends ConsumerStatefulWidget {
  const ParentLinkScreen({super.key});

  @override
  ConsumerState<ParentLinkScreen> createState() => _ParentLinkScreenState();
}

class _ParentLinkScreenState extends ConsumerState<ParentLinkScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _linkedName;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _ykCode(String userId) {
    if (userId.isEmpty) return 'YK-0000-BF';
    final hash = userId.hashCode.abs() % 10000;
    return 'YK-${hash.toString().padLeft(4, '0')}-BF';
  }

  Future<void> _link() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _linkedName = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final db = ref.read(databaseServiceProvider);
    final students = db
        .getAllUsers()
        .where((u) => u.role == 'student')
        .toList();

    UserModel? found;
    for (final student in students) {
      if (_ykCode(student.id) == code) {
        found = student;
        break;
      }
    }

    if (found != null) {
      final parentId = ref.read(authNotifierProvider).userId ?? '';
      if (parentId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur : session invalide. Reconnecte-toi.';
        });
        return;
      }

      final box = Hive.box(HiveBoxes.settings);
      final key = 'parent_links_$parentId';
      final existing = (box.get(key) as String?) ?? '';
      final linked = existing.isEmpty
          ? <String>[]
          : existing.split(',').where((s) => s.isNotEmpty).toList();
      if (!linked.contains(found.id)) {
        linked.add(found.id);
        await box.put(key, linked.join(','));
      }

      setState(() {
        _isLoading = false;
        _linkedName = '${found!.name ?? found.phone} lié(e) avec succès ! 🎉';
      });
    } else {
      setState(() {
        _isLoading = false;
        _error =
            'Code introuvable. Vérifie que ton enfant utilise bien yikri '
            'sur cet appareil, et que son code est exact.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lier un enfant',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D1A00), AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Text('👨‍👩‍👧', style: TextStyle(fontSize: 36)),
                SizedBox(width: 14),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lier ton enfant',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text(
                      'Demande le code yikri de ton enfant depuis son Profil.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 32),

            const Text('Code de ton enfant',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                hintText: 'YK-0000-BF',
                prefixIcon: Icon(Icons.qr_code_rounded),
                hintStyle:
                    TextStyle(fontFamily: 'Nunito', letterSpacing: 2),
              ),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.error))),
                ]),
              ),
            ],

            if (_linkedName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(_linkedName!,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success))),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _link,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Lier cet enfant',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(height: 32),
            const Text('Comment obtenir le code ?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            const SizedBox(height: 12),
            _Step('1', 'Ton enfant ouvre l\'app yikri sur ce téléphone'),
            _Step('2', 'Il va dans Profil (icône en bas à droite)'),
            _Step('3', 'Il copie son code YK-XXXX-BF affiché'),
            _Step('4', 'Il te l\'envoie et tu le saisis ici'),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, text;
  const _Step(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.onSurface))),
      ]),
    );
  }
}
