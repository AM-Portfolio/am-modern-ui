import 'package:equatable/equatable.dart';

/// User entity representing the authenticated user
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.authMethod,
    this.displayName,
    this.photoUrl,
    this.isDemo = false,
  });
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String authMethod; // 'email', 'google', 'demo'
  final bool isDemo;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    authMethod,
    isDemo,
  ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? authMethod,
    bool? isDemo,
  }) => UserEntity(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    authMethod: authMethod ?? this.authMethod,
    isDemo: isDemo ?? this.isDemo,
  );
}
