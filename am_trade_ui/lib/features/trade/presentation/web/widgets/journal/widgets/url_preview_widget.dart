// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlPreviewWidget extends StatefulWidget {
  const UrlPreviewWidget({required this.url, required this.onClose, super.key});

  final String url;
  final VoidCallback onClose;

  @override
  State<UrlPreviewWidget> createState() => _UrlPreviewWidgetState();
}

class _UrlPreviewWidgetState extends State<UrlPreviewWidget> {
  final String _iframeId = 'url-preview-${DateTime.now().millisecondsSinceEpoch}';
  bool _iframeRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerIframe();
  }

  void _registerIframe() {
    if (kIsWeb && !_iframeRegistered) {
      // Register iframe factory for web
      ui_web.platformViewRegistry.registerViewFactory(_iframeId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
      _iframeRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print('UrlPreviewWidget building for: ${widget.url}'); // Debug

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildPreviewArea(theme), _buildUrlText(theme)],
      ),
    );
  }

  Widget _buildPreviewArea(ThemeData theme) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    child: Container(
      height: 200,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          if (kIsWeb) HtmlElementView(viewType: _iframeId) else _buildImagePreview(theme),
          _buildOpenIndicator(),
        ],
      ),
    ),
  );

  Widget _buildImagePreview(ThemeData theme) => Image.network(
    'https://image.thum.io/get/width/1200/crop/800/noanimate/${Uri.encodeComponent(widget.url)}',
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(theme),
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return _buildLoadingIndicator(loadingProgress);
    },
  );

  Widget _buildErrorPlaceholder(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.web, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(
          'Preview Unavailable',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Click to open in browser',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) => Container(
    color: Colors.black12,
    child: Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null,
      ),
    ),
  );

  Widget _buildOpenIndicator() => Positioned(
    top: 8,
    right: 8,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _launchUrl(widget.url),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.open_in_new, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildUrlText(ThemeData theme) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.url,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: widget.onClose,
        ),
      ],
    ),
  );

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
