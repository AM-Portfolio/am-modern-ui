import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Local staging model for one file in a multi-document sync batch.
class PendingSyncFile {
  final Uint8List bytes;
  final String filename;
  String? brokerType;
  String? documentType;
  final TextEditingController portfolioController;
  final TextEditingController passwordController;

  PendingSyncFile({
    required this.bytes,
    required this.filename,
    this.brokerType,
    this.documentType,
    String? portfolioName,
    String? password,
  })  : portfolioController = TextEditingController(text: portfolioName ?? ''),
        passwordController = TextEditingController(text: password ?? '');

  int get sizeBytes => bytes.length;

  String get extensionLabel {
    final ext = filename.contains('.')
        ? filename.split('.').last.toUpperCase()
        : 'FILE';
    if (ext.length > 4) return 'FILE';
    return ext;
  }

  bool get hasExplicitTypes =>
      brokerType != null &&
      brokerType!.isNotEmpty &&
      documentType != null &&
      documentType!.isNotEmpty;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void dispose() {
    portfolioController.dispose();
    passwordController.dispose();
  }
}
