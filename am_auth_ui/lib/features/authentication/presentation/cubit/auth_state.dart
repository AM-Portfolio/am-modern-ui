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
