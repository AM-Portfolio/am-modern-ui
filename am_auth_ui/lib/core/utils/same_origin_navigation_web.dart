import 'dart:html' as html;

const _qaTokenKey = 'am_qa_central_token';
const _qaHandoffKey = 'am_qa_handoff_code';

/// Optional absolute QA portal origin for local split ports (e.g. http://localhost:8151).
const _qaPortalOrigin = String.fromEnvironment(
  'QA_PORTAL_ORIGIN',
  defaultValue: '',
);

void navigateToSameOrigin(
  String path, {
  String? accessToken,
  String? handoffCode,
}) {
  if (!path.startsWith('/qa/ui')) return;

  final token = accessToken?.trim() ?? '';
  final handoff = handoffCode?.trim() ?? '';
  if (token.isNotEmpty) {
    try {
      html.window.sessionStorage[_qaTokenKey] = token;
    } catch (_) {}
  }
  if (handoff.isNotEmpty) {
    try {
      html.window.sessionStorage[_qaHandoffKey] = handoff;
    } catch (_) {}
  }

  if (_qaPortalOrigin.isNotEmpty) {
    // Local Flutter portal is rooted at /login (no /qa ingress prefix).
    final target = Uri.tryParse(path);
    final qp = <String, String>{
      if (target != null) ...target.queryParameters,
      'qa_sso': '1',
      if (handoff.isNotEmpty) 'handoff': handoff,
      // Cross-origin sessionStorage is unavailable; fall back to query JWT.
      if (handoff.isEmpty && token.isNotEmpty) 'am_token': token,
    };
    final dest = Uri.parse(_qaPortalOrigin).replace(
      path: '/login',
      queryParameters: qp,
    );
    html.window.location.assign(dest.toString());
    return;
  }

  final resolved = Uri.base.resolve(path);
  final qp = Map<String, String>.from(resolved.queryParameters)
    ..['qa_sso'] = '1';
  if (handoff.isNotEmpty) {
    qp['handoff'] = handoff;
  }
  html.window.location.assign(
    resolved.replace(queryParameters: qp).toString(),
  );
}
