import 'package:am_design_system/am_design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.sm);
    final placeholder = _NewsThumbPlaceholder(width: width, height: height);
    final src = url?.trim() ?? '';
    if (src.isEmpty) return placeholder;

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
          webHtmlElementStrategy: WebHtmlElementStrategy.never,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder;
          },
          errorBuilder: (_, __, ___) => placeholder,
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
