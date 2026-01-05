import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.authMethod,
    this.displayName,
    this.photoUrl,
    this.isDemo = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
    id: entity.id,
    email: entity.email,
    displayName: entity.displayName,
    photoUrl: entity.photoUrl,
    authMethod: entity.authMethod,
    isDemo: entity.isDemo,
  );
  final String id;
  final String email;
  final String? displayName;
  @JsonKey(name: 'picture')
  final String? photoUrl;
  final String authMethod;
  final bool isDemo;
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    authMethod: authMethod,
    isDemo: isDemo,
  );
}
