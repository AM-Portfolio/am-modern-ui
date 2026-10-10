/// First name for AI chat greetings — never a lone 1-char token when email helps.
String greetingFirstName({String? displayName, String? email}) {
  final fromDisplay = _firstUsableToken(displayName);
  if (fromDisplay != null) return fromDisplay;

  final fromEmail = _firstUsableToken(_nameFromEmail(email ?? ''));
  if (fromEmail != null) return fromEmail;

  return 'there';
}

String? _firstUsableToken(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  for (final part in trimmed.split(RegExp(r'\s+'))) {
    final token = part.replaceAll(RegExp(r'[.]+$'), '').trim();
    if (token.length >= 2) return token;
  }
  return null;
}

String _nameFromEmail(String email) {
  if (!email.contains('@')) return '';
  final local =
      email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
  if (local.isEmpty) return '';
  return local
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
