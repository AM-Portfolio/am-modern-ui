import 'package:flutter/material.dart';

/// Shared context passed to all modules
/// Provides access to common services and state
class ModuleContext {
  const ModuleContext({
    required this.userId,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.isAuthenticated = false,
    this.theme,
    this.onNavigate,
    this.onLogout,
  });

  /// Current user ID (null if not authenticated)
  final String userId;

  /// Current user name
  final String? userName;

  /// Current user email
  final String? userEmail;

  /// Current user avatar URL
  final String? userAvatarUrl;

  /// Whether user is authenticated
  final bool isAuthenticated;

  /// Current theme data
  final ThemeData? theme;

  /// Navigation callback
  /// Call this to navigate to another module or route
  final Function(String route)? onNavigate;

  /// Logout callback
  final VoidCallback? onLogout;

  /// Create a copy with modified fields
  ModuleContext copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
    bool? isAuthenticated,
    ThemeData? theme,
    Function(String route)? onNavigate,
    VoidCallback? onLogout,
  }) {
    return ModuleContext(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      theme: theme ?? this.theme,
      onNavigate: onNavigate ?? this.onNavigate,
      onLogout: onLogout ?? this.onLogout,
    );
  }

  /// Create an empty/default context
  factory ModuleContext.empty() {
    return const ModuleContext(
      userId: '',
      isAuthenticated: false,
    );
  }
}
