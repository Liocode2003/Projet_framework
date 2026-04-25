import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../models/user_model.dart';

/// Supabase-backed auth operations.
/// All methods throw [AuthException] on failure.
///
/// Prerequisites (Supabase dashboard):
///   1. Enable Phone provider under Authentication → Providers
///   2. Configure Twilio (or Vonage) for SMS OTP delivery
///   3. Run the SQL migration in supabase/migrations/001_initial_schema.sql
class AuthRemoteDataSource {
  // ── OTP ────────────────────────────────────────────────────────────────────

  /// Sends an SMS OTP to [phone] via Supabase → Twilio.
  /// [phone] should be 8-digit local format; we add +226 for Burkina Faso.
  Future<void> sendOtp(String phone) async {
    try {
      await SupabaseService.client.auth.signInWithOtp(
        phone: _toE164(phone),
      );
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Envoi OTP échoué : $e');
    }
  }

  /// Verifies the OTP and returns the Supabase user ID.
  Future<String> verifyOtp(String phone, String otp) async {
    try {
      final res = await SupabaseService.client.auth.verifyOTP(
        phone: _toE164(phone),
        token: otp,
        type: OtpType.sms,
      );
      final userId = res.user?.id;
      if (userId == null) throw AuthException('Vérification échouée.');

      // Upsert profile row (idempotent — safe to call on every login)
      await SupabaseService.client.from('profiles').upsert({
        'id':    userId,
        'phone': phone,
      }, onConflict: 'id');

      return userId;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Vérification OTP échouée : $e');
    }
  }

  // ── Profile sync ──────────────────────────────────────────────────────────

  Future<void> saveRole(String userId, String role) async {
    await SupabaseService.client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  Future<void> saveConsent(String userId) async {
    await SupabaseService.client
        .from('profiles')
        .update({'consent_given': true})
        .eq('id', userId);
  }

  Future<void> saveProfile(
      String userId, String name, String? gradeLevel) async {
    await SupabaseService.client.from('profiles').update({
      'name':        name,
      'grade_level': gradeLevel,
    }).eq('id', userId);
  }

  Future<UserModel?> fetchProfile(String userId) async {
    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel(
      id:           data['id'] as String,
      phone:        data['phone'] as String? ?? '',
      role:         data['role'] as String? ?? 'student',
      name:         data['name'] as String?,
      gradeLevel:   data['grade_level'] as String?,
      schoolName:   data['school_name'] as String?,
      pinHash:      '',   // PIN stays local
      createdAt:    data['created_at'] as String? ??
                    DateTime.now().toIso8601String(),
      consentGiven: data['consent_given'] as bool? ?? false,
    );
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
  }

  bool get hasActiveSession => SupabaseService.currentSession != null;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts an 8-digit Burkina Faso number to E.164 (+226XXXXXXXX).
  static String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('226')) return '+$digits';
    if (digits.startsWith('+')) return digits;
    return '+226$digits';
  }
}
