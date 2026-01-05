import 'package:flutter/material.dart';

/// Stub for UrlPreviewWidget to avoid dart:html imports on mobile
class UrlPreviewWidget extends StatelessWidget {
  const UrlPreviewWidget({required this.url, required this.onClose, super.key});

  final String url;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
