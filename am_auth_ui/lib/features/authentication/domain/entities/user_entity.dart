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
    this.roles = const [],
  });
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String authMethod; // 'email', 'google', 'demo'
  final bool isDemo;
  final List<String> roles;

  /// Admin if JWT roles/scopes include `admin`, `super_admin`, or `role_admin`.
  bool get isAdmin {
    for (final role in roles) {
      final normalized = role.toLowerCase().replaceAll('-', '_');
      if (normalized == 'admin' ||
          normalized == 'super_admin' ||
          normalized == 'role_admin') {
        return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    authMethod,
    isDemo,
    roles,
  ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? authMethod,
    bool? isDemo,
    List<String>? roles,
  }) => UserEntity(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    authMethod: authMethod ?? this.authMethod,
    isDemo: isDemo ?? this.isDemo,
    roles: roles ?? this.roles,
  );
}
