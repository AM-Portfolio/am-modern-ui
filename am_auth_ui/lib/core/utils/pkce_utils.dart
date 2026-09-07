import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String generateCodeVerifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

String codeChallengeFromVerifier(String verifier) {
  final digest = sha256.convert(utf8.encode(verifier));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

String formatConfirmationCode(String code) {
  final digits = code.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 6) return code;
  return '${digits.substring(0, 3)} ${digits.substring(3)}';
}
