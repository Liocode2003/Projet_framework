import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Auth flow states — drives screen transitions via GoRouter.
enum AuthStatus {
  initial,       // not checked yet
  unauthenticated,
  otpSent,       // phone submitted, waiting for OTP
  otpVerified,   // userId obtained, choosing role
  roleSelected,  // role set, showing consent
  consentGiven,  // ready to set PIN
  authenticated, // full session established
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? phone;
  final String? userId;
  final String? role;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.phone,
    this.userId,
    this.role,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  const AuthState.initial()
      : this(status: AuthStatus.initial);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? userId,
    String? role,
    UserEntity? user,
    String? errorMessage,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        phone: phone ?? this.phone,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        user: user ?? this.user,
        errorMessage: errorMessage,   // always nullable — explicit reset
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props =>
      [status, phone, userId, role, user, errorMessage, isLoading];
}
