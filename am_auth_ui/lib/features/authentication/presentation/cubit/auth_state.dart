import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Authentication sealed state
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state
final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Session restore failed transiently (network/server) — refresh token still present.
final class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Authentication error state
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Password reset email sent state
final class PasswordResetEmailSent extends AuthState {
  const PasswordResetEmailSent();
}

/// Password reset success state
final class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

/// Email verification succeeded
final class EmailVerificationSuccess extends AuthState {
  const EmailVerificationSuccess();
}

/// Registration created; user must verify email before login
final class RegisterPendingVerification extends AuthState {
  const RegisterPendingVerification(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}
