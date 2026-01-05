import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_tokens_entity.dart';

part 'auth_tokens_model.g.dart';

@JsonSerializable()
class AuthTokensModel {
  AuthTokensModel({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);

  factory AuthTokensModel.fromEntity(AuthTokensEntity entity) =>
      AuthTokensModel(
        accessToken: entity.accessToken,
        refreshToken: entity.refreshToken,
        expiresAt: entity.expiresAt,
      );
  final String accessToken;
  final String? refreshToken;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime expiresAt;
  Map<String, dynamic> toJson() => _$AuthTokensModelToJson(this);

  AuthTokensEntity toEntity() => AuthTokensEntity(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
  );

  static DateTime _dateTimeFromJson(String dateTimeString) =>
      DateTime.parse(dateTimeString);

  static String _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();
}
