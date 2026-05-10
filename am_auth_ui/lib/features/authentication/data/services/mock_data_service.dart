import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/constants/auth_constants.dart';
import '../models/auth_result_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// Service for providing mock authentication data
class MockDataService {
  final FeatureFlags _featureFlags = FeatureFlags();

  /// Load mock users from JSON
  Future<List<UserModel>> loadMockUsers() async {
    final response = await rootBundle.loadString(
      'assets/mock-data/users/auth_users.json',
    );
    final Map<String, dynamic> data = json.decode(response);
    final List<dynamic> authUsers = data['auth_users'];
    return authUsers.map((json) => UserModel.fromJson(json)).toList();
  }

  /// Load mock Google users from JSON
  Future<List<UserModel>> loadMockGoogleUsers() async {
    final response = await rootBundle.loadString(
      'assets/mock-data/google/oauth_profiles.json',
    );
    final Map<String, dynamic> data = json.decode(response);
    final List<dynamic> googleProfiles = data['google_profiles'];
    return googleProfiles.map((json) => UserModel.fromJson(json)).toList();
  }

  /// Load test users from default JSON
  Future<List<Map<String, dynamic>>> loadTestUsers() async {
    final response = await rootBundle.loadString(
      'packages/am_auth_ui/assets/test_users.json',
    );
    final Map<String, dynamic> data = json.decode(response);
    final List<dynamic> users = data['users'];
    return users.cast<Map<String, dynamic>>();
  }

  /// Authenticate user with email and password (mock)
  Future<AuthResultModel?> authenticateEmailPassword(
    String email,
    String password,
  ) async {
    // Simulate API delay
    if (_featureFlags.enableMockDelays) {
      await Future.delayed(
        Duration(milliseconds: _featureFlags.mockApiDelayMs),
      );
    }

    // Simulate error if enabled
    if (_featureFlags.enableErrorSimulation &&
        _shouldSimulateError(_featureFlags.authErrorRate)) {
      return null;
    }

    // First try test_users.json (default JSON)
    final testUsers = await loadTestUsers();
    final testUserJson = testUsers.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u!['email'] == email && u['password'] == password,
      orElse: () => null,
    );

    if (testUserJson != null) {
      // Map from test_users.json format to UserModel format
      final user = UserModel(
        id: testUserJson['id'] as String,
        email: testUserJson['email'] as String,
        displayName: testUserJson['name'] as String? ?? 'User',
        authMethod: AuthConstants.authMethodEmail,
        isDemo: false,
      );
      final tokens = _generateMockTokens(user.id);
      return AuthResultModel(user: user, tokens: tokens);
    }

    // Fallback to mock users if not found in test users
    final users = await loadMockUsers();
    final user = users.cast<UserModel?>().firstWhere(
      (u) => u!.email == email,
      orElse: () => null,
    );

    if (user != null) {
      // In a real implementation, verify password hash
      // For mock, we'll use simple comparison
      final tokens = _generateMockTokens(user.id);
      return AuthResultModel(user: user, tokens: tokens);
    }

    return null;
  }

  /// Authenticate with Google (mock)
  Future<AuthResultModel> authenticateGoogle() async {
    // Simulate API delay
    if (_featureFlags.enableMockDelays) {
      await Future.delayed(
        Duration(milliseconds: _featureFlags.mockApiDelayMs),
      );
    }

    final googleUsers = await loadMockGoogleUsers();
    final user = googleUsers.first; // Use first Google user for mock
    final tokens = _generateMockTokens(user.id);

    return AuthResultModel(user: user, tokens: tokens);
  }

  /// Authenticate demo user
  Future<AuthResultModel> authenticateDemo() async {
    // Simulate API delay
    if (_featureFlags.enableMockDelays) {
      await Future.delayed(
        Duration(milliseconds: _featureFlags.mockApiDelayMs),
      );
    }

    // Load users from test_users.json (default JSON)
    final testUsers = await loadTestUsers();
    
    // Find demo user or fallback to first user
    UserModel user;
    final demoUserJson = testUsers.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u!['email'] == 'ssd2658@gmail.com' || u['username'] == '64d5f6c9-9516-4eca-ac45-c73cfff7a8ec',
      orElse: () => null,
    );
    
    if (demoUserJson != null) {
      // Map from test_users.json format to UserModel format
      user = UserModel(
        id: demoUserJson['id'] as String,
        email: demoUserJson['email'] as String,
        displayName: demoUserJson['name'] as String? ?? 'Demo User',
        authMethod: AuthConstants.authMethodDemo,
        isDemo: true,
      );
    } else {
      // Fallback to first user if demo user not found
      final fallbackUserJson = testUsers.first;
      user = UserModel(
        id: fallbackUserJson['id'] as String,
        email: fallbackUserJson['email'] as String,
        displayName: fallbackUserJson['name'] as String? ?? 'Demo User',
        authMethod: AuthConstants.authMethodDemo,
        isDemo: true,
      );
    }

    final tokens = _generateMockTokens(user.id);

    return AuthResultModel(user: user, tokens: tokens);
  }

  /// Generate mock authentication tokens
  AuthTokensModel _generateMockTokens(String userId) {
    final now = DateTime.now();
    final expiresAt = now.add(AuthConstants.tokenExpiryDuration);

    return AuthTokensModel(
      accessToken: _generateMockToken('access', userId),
      refreshToken: _generateMockToken('refresh', userId),
      expiresAt: expiresAt,
    );
  }

  /// Generate a mock token string
  String _generateMockToken(String type, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Dummy JWT format: header.payload.signature
    final header = 'eyJhbGciOiJub25lIn0=';
    final payloadJson = '{"sub":"$userId","iat":$timestamp,"type":"$type"}';
    final payload = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
    return '$header.$payload.dummy_signature';
  }

  /// Simulate error based on error rate
  bool _shouldSimulateError(double errorRate) {
    if (errorRate <= 0) return false;
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < (errorRate * 100);
  }
}
