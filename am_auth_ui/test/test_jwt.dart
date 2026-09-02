import 'dart:convert';

String testJwt({Duration validFor = const Duration(hours: 1)}) {
  final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url
      .encode(utf8.encode('{"exp":$exp}'))
      .replaceAll('=', '');
  return 'hdr.$payload.sig';
}
