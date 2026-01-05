import 'package:equatable/equatable.dart';
import 'user_entity.dart';
import 'auth_tokens_entity.dart';

/// Authentication result entity
class AuthResultEntity extends Equatable {
  const AuthResultEntity({required this.user, required this.tokens});
  final UserEntity user;
  final AuthTokensEntity tokens;

  @override
  List<Object?> get props => [user, tokens];

  AuthResultEntity copyWith({UserEntity? user, AuthTokensEntity? tokens}) =>
      AuthResultEntity(user: user ?? this.user, tokens: tokens ?? this.tokens);
}
