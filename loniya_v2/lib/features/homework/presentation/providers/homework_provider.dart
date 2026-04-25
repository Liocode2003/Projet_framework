import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/datasources/homework_remote_datasource.dart';
import '../../data/models/homework_model.dart';

class HomeworkNotifier extends StateNotifier<List<HomeworkModel>> {
  HomeworkNotifier._({required this.userId, required this.role}) : super([]) {
    _load();
    _syncFromRemote(); // background sync — UI sees local data immediately
  }

  factory HomeworkNotifier.create(
          {required String userId, required String role}) =>
      HomeworkNotifier._(userId: userId, role: role);

  final String userId;
  final String role;

  // ── Local load ─────────────────────────────────────────────────────────────

  void _load() {
    final box = Hive.box(HiveBoxes.homework);
    final all = box.values.whereType<HomeworkModel>().toList();

    if (role == 'student') {
      state = all
          .where((h) => h.studentId.isEmpty || h.studentId == userId)
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      if (!box.containsKey('demo_hw_1')) _seedDemo();
    } else {
      state = all
          .where((h) => h.teacherId == userId)
          .toList()
        ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    }
  }

  // ── Remote sync ────────────────────────────────────────────────────────────

  Future<void> _syncFromRemote() async {
    if (!SupabaseService.isAvailable || userId.isEmpty) return;
    try {
      final remote = role == 'student'
          ? await HomeworkRemoteDataSource().fetchForStudent(userId)
          : await HomeworkRemoteDataSource().fetchForTeacher(userId);

      final box = Hive.box(HiveBoxes.homework);
      for (final hw in remote) {
        box.put(hw.id, hw);
      }
      if (mounted) _load();
    } catch (_) {
      // Silent — keep using local data
    }
  }

  /// Call this from UI pull-to-refresh to force a re-sync.
  Future<void> refresh() => _syncFromRemote();

  // ── Demo seed (students only, first launch) ────────────────────────────────

  void _seedDemo() {
    final now = DateTime.now();
    final demos = [
      HomeworkModel(
        id: 'demo_hw_1',
        studentId: '', teacherId: 'system', classCode: '',
        title: 'Exercices — Tableaux et proportionnalité',
        subject: 'Mathématiques',
        deadline: now.add(const Duration(days: 2)).toIso8601String(),
        durationMin: 45,
        assignedAt: now.subtract(const Duration(days: 1)).toIso8601String(),
      ),
      HomeworkModel(
        id: 'demo_hw_2',
        studentId: '', teacherId: 'system', classCode: '',
        title: 'Lecture : Le vieux Saltimbanque — résumé et réactions',
        subject: 'Français',
        deadline: now.add(const Duration(hours: 22)).toIso8601String(),
        durationMin: 30,
        assignedAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
      HomeworkModel(
        id: 'demo_hw_3',
        studentId: '', teacherId: 'system', classCode: '',
        title: 'Résumé : Les indépendances africaines (1960)',
        subject: 'Histoire-Géographie',
        deadline: now.add(const Duration(days: 5)).toIso8601String(),
        durationMin: 60, status: 'done', score: 15,
        assignedAt: now.subtract(const Duration(days: 4)).toIso8601String(),
      ),
      HomeworkModel(
        id: 'demo_hw_4',
        studentId: '', teacherId: 'system', classCode: '',
        title: 'Apprendre le vocabulaire — Unit 4 : At school',
        subject: 'Anglais',
        deadline: now.add(const Duration(days: 3)).toIso8601String(),
        durationMin: 20,
        assignedAt: now.subtract(const Duration(hours: 12)).toIso8601String(),
      ),
    ];
    final box = Hive.box(HiveBoxes.homework);
    for (final hw in demos) { box.put(hw.id, hw); }
    state = demos;
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> create({
    required String title,
    required String subject,
    required int durationMin,
    required DateTime deadline,
  }) async {
    final hw = HomeworkModel(
      id: const Uuid().v4(),
      studentId: '', teacherId: userId, classCode: '',
      title: title, subject: subject,
      deadline: deadline.toIso8601String(),
      durationMin: durationMin,
      assignedAt: DateTime.now().toIso8601String(),
    );
    await Hive.box(HiveBoxes.homework).put(hw.id, hw);
    if (SupabaseService.isAvailable) {
      HomeworkRemoteDataSource().create(hw).ignore();
    }
    _load();
  }

  Future<void> markDone(String id, {required int score}) async {
    final box = Hive.box(HiveBoxes.homework);
    final hw = box.get(id) as HomeworkModel?;
    if (hw == null) return;
    await box.put(id, hw.copyWith(status: 'done', score: score));
    if (SupabaseService.isAvailable) {
      HomeworkRemoteDataSource().updateStatus(id, 'done', score: score).ignore();
    }
    _load();
  }

  Future<void> delete(String id) async {
    await Hive.box(HiveBoxes.homework).delete(id);
    if (SupabaseService.isAvailable) {
      HomeworkRemoteDataSource().delete(id).ignore();
    }
    _load();
  }
}

final homeworkNotifierProvider =
    StateNotifierProvider<HomeworkNotifier, List<HomeworkModel>>((ref) {
  final auth = ref.watch(authNotifierProvider);
  return HomeworkNotifier.create(
    userId: auth.userId ?? '',
    role:   auth.user?.role ?? 'student',
  );
});
