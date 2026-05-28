/// Helpers for trade API requests that derive user identity from the auth token.
Map<String, dynamic> tradeRequestBodyWithoutUserId(Map<String, dynamic> body) {
  final copy = Map<String, dynamic>.from(body);
  copy.remove('userId');
  return copy;
}
