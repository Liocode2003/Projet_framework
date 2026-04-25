import '../../../../core/services/supabase/supabase_service.dart';
import '../models/homework_model.dart';

/// Supabase-backed homework operations.
/// All methods are silent on network failure — callers use local Hive as truth.
class HomeworkRemoteDataSource {
  // ── Fetch ───────────────────────────────────────────────────────────────────

  Future<List<HomeworkModel>> fetchForStudent(String userId) async {
    final data = await SupabaseService.client
        .from('homework')
        .select()
        .or('student_id.eq.$userId,student_id.is.null')
        .order('deadline', ascending: true);
    return (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<HomeworkModel>> fetchForTeacher(String teacherId) async {
    final data = await SupabaseService.client
        .from('homework')
        .select()
        .eq('teacher_id', teacherId)
        .order('assigned_at', ascending: false);
    return (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  Future<void> create(HomeworkModel hw) async {
    await SupabaseService.client.from('homework').insert(_toRow(hw));
  }

  Future<void> updateStatus(
      String id, String status, {int? score}) async {
    await SupabaseService.client.from('homework').update({
      'status': status,
      if (score != null) 'score': score,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await SupabaseService.client
        .from('homework')
        .delete()
        .eq('id', id);
  }

  // ── Serialization ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _toRow(HomeworkModel h) => {
    'id':           h.id,
    'teacher_id':   h.teacherId.isEmpty ? null : h.teacherId,
    'student_id':   h.studentId.isEmpty ? null : h.studentId,
    'class_code':   h.classCode,
    'title':        h.title,
    'subject':      h.subject,
    'deadline':     h.deadline,
    'duration_min': h.durationMin,
    'course_id':    h.courseId,
    'status':       h.status,
    'score':        h.score,
    'assigned_at':  h.assignedAt,
  };

  static HomeworkModel _fromRow(Map<String, dynamic> r) => HomeworkModel(
    id:          r['id'] as String,
    teacherId:   r['teacher_id'] as String? ?? '',
    studentId:   r['student_id'] as String? ?? '',
    classCode:   r['class_code'] as String? ?? '',
    title:       r['title'] as String,
    subject:     r['subject'] as String,
    deadline:    r['deadline'] as String,
    durationMin: r['duration_min'] as int? ?? 30,
    courseId:    r['course_id'] as String? ?? '',
    status:      r['status'] as String? ?? 'pending',
    score:       r['score'] as int?,
    assignedAt:  r['assigned_at'] as String? ?? DateTime.now().toIso8601String(),
  );
}
