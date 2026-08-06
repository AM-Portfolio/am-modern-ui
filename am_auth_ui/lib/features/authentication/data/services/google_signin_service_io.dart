import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/constants/auth_constants.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import 'package:am_design_system/core/utils/common_logger.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

/// Google Sign-In account (IO / mobile)
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

/// Google Sign-In authentication (IO / mobile)
class GoogleSignInAuthentication {
  GoogleSignInAuthentication({required this.idToken});

  final String? idToken;
}

/// Google Sign-In via native Android / iOS SDK.
///
/// [serverClientId] must be the Web OAuth client ID so Google returns an
/// ID token the backend can verify (same client used by the web GIS flow).
class GoogleSignInService {
  gsi.GoogleSignIn? _googleSignIn;
  gsi.GoogleSignInAccount? _currentUser;

  String get _serverClientId {
    try {
      final configClientId = ConfigService.config.google.webClientId;
      if (configClientId.isNotEmpty) {
        return configClientId;
      }
    } catch (_) {
      // Config may not be ready in early tests; fall back to AuthConstants.
    }
    return AuthConstants.googleClientId;
  }

  gsi.GoogleSignIn get _client {
    return _googleSignIn ??= gsi.GoogleSignIn(
      scopes: const <String>['email', 'openid', 'profile'],
      serverClientId: _serverClientId,
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      CommonLogger.info('Google Sign-In (IO): starting native flow');
      final account = await _client.signIn();
      if (account == null) {
        CommonLogger.info('Google Sign-In (IO): cancelled by user');
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        CommonLogger.error(
          'Google Sign-In (IO): idToken missing — check Android OAuth client '
          'and Play App Signing SHA-1/256 against Google Cloud',
        );
        throw AuthException(
          'Google Sign-In did not return an ID token. '
          'Verify the Android OAuth client and Play signing certificate.',
        );
      }

      _currentUser = account;
      CommonLogger.info('Google Sign-In (IO): success for ${account.email}');
      return GoogleSignInAccount(
        email: account.email,
        id: account.id,
        idToken: idToken,
      );
    } on AuthException {
      rethrow;
    } catch (e, st) {
      CommonLogger.error('Google Sign-In (IO) failed: $e\n$st');
      throw AuthException(AuthConstants.googleSignInFailed);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.signOut();
      _currentUser = null;
      CommonLogger.info('Google Sign-Out (IO): complete');
    } catch (e) {
      CommonLogger.error('Google Sign-Out (IO) error: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      return await _client.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  GoogleSignInAccount? getCurrentAccount() {
    final account = _currentUser ?? _client.currentUser;
    if (account == null) {
      return null;
    }
    return GoogleSignInAccount(
      email: account.email,
      id: account.id,
      idToken: '',
    );
  }
}
