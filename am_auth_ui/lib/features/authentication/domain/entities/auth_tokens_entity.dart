import 'package:equatable/equatable.dart';

/// Authentication tokens entity
class AuthTokensEntity extends Equatable {
  const AuthTokensEntity({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];

  AuthTokensEntity copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) => AuthTokensEntity(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}
