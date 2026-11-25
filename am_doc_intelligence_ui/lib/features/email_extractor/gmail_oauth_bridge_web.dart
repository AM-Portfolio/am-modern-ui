// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

/// Web: popup + `window.onMessage` for `am-gmail-oauth`.
class GmailOauthBridge {
  StreamSubscription<html.MessageEvent>? _sub;
  void Function(GmailOauthEvent event)? _onEvent;

  void listen({
    void Function(GmailOauthEvent event)? onOauthEvent,
    void Function()? onAppResumed,
  }) {
    _onEvent = onOauthEvent;
    _sub?.cancel();
    _sub = html.window.onMessage.listen(_onMessage);
    // onAppResumed unused on web — popup + postMessage cover return.
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _onEvent = null;
  }

  void _onMessage(html.MessageEvent event) {
    final data = event.data;
    if (data is! Map) return;
    if (data['type'] != 'am-gmail-oauth') return;
    if (data['success'] == true) {
      final email = data['email']?.toString();
      _onEvent?.call(GmailOauthEvent(
        success: true,
        email: (email != null && email.isNotEmpty) ? email : null,
      ));
    } else {
      _onEvent?.call(GmailOauthEvent(
        success: false,
        error: data['error']?.toString() ?? 'unknown',
      ));
    }
  }

  Map<String, String>? readGmailQueryParams() {
    try {
      final uri = Uri.parse(html.window.location.href);
      final gmail = uri.queryParameters['gmail'];
      if (gmail == null || gmail.isEmpty) return null;
      return {
        'gmail': gmail,
        if (uri.queryParameters['msg'] != null)
          'msg': uri.queryParameters['msg']!,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAuthUrl(String authUrl) async {
    html.window.open(
      authUrl,
      'am_gmail_oauth',
      'width=520,height=720',
    );
    return true;
  }
}
