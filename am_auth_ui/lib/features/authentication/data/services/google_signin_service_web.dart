import 'package:am_design_system/am_design_system.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:am_design_system/core/constants/auth_constants.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import 'package:am_common/core/utils/logger.dart';

/// Google Sign-In account
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

/// Google Sign-In authentication
class GoogleSignInAuthentication {
  GoogleSignInAuthentication({required this.idToken});

  final String? idToken;
}

/// Service for Google Sign-In using Google Identity Services (web)
class GoogleSignInService {
  Completer<GoogleSignInAccount?>? _signInCompleter;
  bool _initialized = false;

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      print('🔵 Google Sign-In: Starting...');
      CommonLogger.info('🔵 Google Sign-In: Starting...');

      // Create new completer for this sign-in attempt
      _signInCompleter = Completer<GoogleSignInAccount?>();
      print('🔵 Created new completer');

      // Check if Google Identity Services is loaded
      final google = js.context['google'];
      if (google == null) {
        throw AuthException(
          'Google Identity Services not loaded. Check index.html',
        );
      }

      final accounts = google['accounts'];
      if (accounts == null) {
        throw AuthException('Google Accounts API not available');
      }

      final id = accounts['id'];
      if (id == null) {
        throw AuthException('Google ID API not available');
      }

      // Initialize Google Sign-In (once)
      if (!_initialized) {
        CommonLogger.info('🔵 Initializing Google Identity Services...');

        id.callMethod('initialize', [
          js.JsObject.jsify({
            'client_id':
                '536930944518-v4406qrrj4o2pk594g2rc3sk6lfinlf6.apps.googleusercontent.com',
            'callback': js.allowInterop(_handleCredentialResponse),
            'use_fedcm_for_prompt': false,
          }),
        ]);

        _initialized = true;
      }

      // Open Google Sign-In popup directly
      print('🔵 Opening Google Sign-In popup window...');
      CommonLogger.info('🔵 Opening Google Sign-In popup window...');
      
      final clientId = '536930944518-v4406qrrj4o2pk594g2rc3sk6lfinlf6.apps.googleusercontent.com';
      print('🔵 Using client ID: ${clientId.substring(0, 20)}...');
      
      // Dynamically determine redirect URI based on current origin
      final currentOrigin = html.window.location.origin;
      final redirectUri = Uri.encodeComponent('$currentOrigin/oauth_callback.html');
      print('🔵 Redirect URI: $redirectUri');
      
      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?'
          'client_id=$clientId&'
          'redirect_uri=$redirectUri&'
          'response_type=token id_token&'
          'scope=openid email profile&'
          'nonce=${DateTime.now().millisecondsSinceEpoch}';
      
      // Open popup window
      final popup = html.window.open(
        authUrl,
        'Google Sign-In',
        'width=500,height=600,menubar=no,toolbar=no',
      );
      
      if (popup == null) {
        print('❌ Popup was blocked!');
        throw AuthException('Popup was blocked. Please allow popups for localhost:3000');
      }
      print('✅ Popup window opened successfully');
      
      // Listen for the callback from the popup window
      late StreamSubscription<html.MessageEvent> subscription;
      subscription = html.window.onMessage.listen((event) {
        print('🔵 Received message from popup: ${event.data}');
        CommonLogger.info('🔵 Received message from popup: ${event.data}');
        
        try {
          if (event.data != null) {
            // Handle both string and object data
            dynamic data = event.data;
            String? idToken;
            
            // If it's a Map, extract the id_token
            if (data is Map) {
              if (data['type'] == 'google-signin-success') {
                idToken = data['id_token']?.toString();
                CommonLogger.info('🔵 Extracted ID token from message');
              }
            }
            
            if (idToken != null && idToken.isNotEmpty) {
              final account = GoogleSignInAccount(
                email: 'google-user',
                id: 'google-id',
                idToken: idToken,
              );
              
              if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
                CommonLogger.info('✅ Completing sign-in with token');
                _signInCompleter!.complete(account);
                subscription.cancel();
              }
            }
          }
        } catch (e) {
          CommonLogger.error('Error processing message: $e');
        }
      });

      // Wait for the callback
      print('⏳ Waiting for callback from popup (60s timeout)...');
      final account = await _signInCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('❌ TIMEOUT: No response from popup window after 60 seconds');
          throw AuthException('Google Sign-In timeout. Please try again.');
        },
      );

      print('✅ Google Sign-In successful!');
      CommonLogger.info('✅ Google Sign-In successful!');
      return account;
    } catch (e) {
      print('❌ Google Sign-In failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      CommonLogger.error('❌ Google Sign-In failed: $e');
      throw AuthException(AuthConstants.googleSignInFailed);
    }
  }

  /// Handle credential response from Google
  void _handleCredentialResponse(dynamic response) {
    try {
      CommonLogger.info('🔵 Received credential from Google');

      final credential = response['credential'];
      if (credential != null) {
        final idToken = credential.toString();

        CommonLogger.info('🔵 ID Token received (length: ${idToken.length})');

        final account = GoogleSignInAccount(
          email: 'google-user', // Backend will decode from token
          id: 'google-id',
          idToken: idToken,
        );

        if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
          _signInCompleter!.complete(account);
        }
      } else {
        CommonLogger.error('❌ No credential in response');
        if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
          _signInCompleter!.completeError(
            AuthException('No credential received from Google'),
          );
        }
      }
    } catch (e) {
      CommonLogger.error('❌ Error handling credential: $e');
      if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
        _signInCompleter!.completeError(e);
      }
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      final google = js.context['google'];
      final accounts = google?['accounts'];
      final id = accounts?['id'];
      id?.callMethod('disableAutoSelect', []);

      _initialized = false;
      CommonLogger.info('✅ Google Sign-Out complete');
    } catch (e) {
      CommonLogger.error('Google sign out error: $e');
    }
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async => false;

  /// Get currently signed in account
  GoogleSignInAccount? getCurrentAccount() => null;
}
