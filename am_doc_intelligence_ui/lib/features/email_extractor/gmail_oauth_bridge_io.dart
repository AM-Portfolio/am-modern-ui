import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// Result from a completed OAuth handoff (web postMessage / deep link).
class GmailOauthEvent {
  const GmailOauthEvent({
    required this.success,
    this.email,
    this.error,
  });

  final bool success;
  final String? email;
  final String? error;
}

/// Native: open Google sign-in in the system browser.
/// Completion is detected by polling Gmail status after the user returns.
class GmailOauthBridge with WidgetsBindingObserver {
  void Function()? _onAppResumed;
  bool _observing = false;

  /// [onOauthEvent] is unused on native (no popup postMessage).
  /// [onAppResumed] refreshes status when returning from the browser.
  void listen({
    void Function(GmailOauthEvent event)? onOauthEvent,
    void Function()? onAppResumed,
  }) {
    // Keep named API aligned with web; events come from status polling.
    onOauthEvent;
    _onAppResumed = onAppResumed;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _onAppResumed = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed?.call();
    }
  }

  /// Native has no page query params for OAuth return.
  Map<String, String>? readGmailQueryParams() => null;

  Future<bool> openAuthUrl(String authUrl) async {
    final uri = Uri.parse(authUrl);
    if (await launcher.canLaunchUrl(uri)) {
      return launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
    return false;
  }
}
