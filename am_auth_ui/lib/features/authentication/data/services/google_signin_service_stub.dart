import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';

import 'dart:async';

import 'package:am_design_system/core/errors/exceptions.dart';
import 'package:am_common/am_common.dart';

/// Google Sign-In account (Stub)
class GoogleSignInAccount {
  GoogleSignInAccount({
    required this.email,
    required this.id,
    required this.idToken,
  });

  final String email;
  final String id;
  final String idToken;

  Future<GoogleSignInAuthentication> get authentication async =>
      GoogleSignInAuthentication(idToken: idToken);
}

/// Google Sign-In authentication (Stub)
class GoogleSignInAuthentication {
  GoogleSignInAuthentication({required this.idToken});

  final String? idToken;
}

/// Service for Google Sign-In (Stub/Mobile)
class GoogleSignInService {
  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    CommonLogger.warning('Google Sign-In not implemented for mobile in this Service stub.');
    throw AuthException('Google Sign-In not supported on mobile (Stub)');
  }

  /// Sign out from Google
  Future<void> signOut() async {
    CommonLogger.info('Google Sign-Out (Stub)');
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async => false;

  /// Get currently signed in account
  GoogleSignInAccount? getCurrentAccount() => null;
}

