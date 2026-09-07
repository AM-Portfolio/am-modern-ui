import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NewsThumbnail extends StatelessWidget {
  const NewsThumbnail({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  static bool _isAbsoluteHttpUrl(String src) {
    final uri = Uri.tryParse(src);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.sm);
    final placeholder = _NewsThumbPlaceholder(width: width, height: height);
    final src = url?.trim() ?? '';
    if (src.isEmpty || !_isAbsoluteHttpUrl(src)) return placeholder;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          src,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          // Prefer bytes for ClipRRect; fall back to HTML <img> on web CDN failures.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder;
          },
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('NewsThumbnail failed url=$src error=$error');
            }
            return placeholder;
          },
        ),
      ),
    );
  }
}

class _NewsThumbPlaceholder extends StatelessWidget {
  const _NewsThumbPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: context.colors.border),
      ),
      child: Icon(
        Icons.article_outlined,
        color: context.colors.textSecondary,
        size: height < 64 ? 20 : 28,
      ),
    );
  }
}
