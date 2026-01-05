import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_result_entity.dart';
import 'auth_tokens_model.dart';
import 'user_model.dart';

part 'auth_result_model.g.dart';

@JsonSerializable()
class AuthResultModel {
  AuthResultModel({required this.user, required this.tokens});

  factory AuthResultModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResultModelFromJson(json);

  factory AuthResultModel.fromEntity(AuthResultEntity entity) =>
      AuthResultModel(
        user: UserModel.fromEntity(entity.user),
        tokens: AuthTokensModel.fromEntity(entity.tokens),
      );
  final UserModel user;
  final AuthTokensModel tokens;
  Map<String, dynamic> toJson() => _$AuthResultModelToJson(this);

  AuthResultEntity toEntity() =>
      AuthResultEntity(user: user.toEntity(), tokens: tokens.toEntity());
}
