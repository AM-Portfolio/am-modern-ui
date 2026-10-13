import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IpoDocumentsCard extends StatelessWidget {
  final String? rhpUrl;
  final String? drhpUrl;

  const IpoDocumentsCard({super.key, this.rhpUrl, this.drhpUrl});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AmBreakpoints.mobile;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: ModuleColors.market,
              ),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDocRow(
            context,
            label: 'RHP PDF',
            url: rhpUrl,
            emphasize: true,
          ),
          const SizedBox(height: 10),
          _buildDocRow(
            context,
            label: 'DRHP PDF',
            url: drhpUrl,
            emphasize: false,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: context.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Read the official RHP for detailed information before investing.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocRow(
    BuildContext context, {
    required String label,
    required String? url,
    required bool emphasize,
  }) {
    final hasUrl = url != null && url.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = !hasUrl
        ? context.surfaceColor.withValues(alpha: isDark ? 0.4 : 1)
        : (emphasize
            ? ModuleColors.market.withValues(alpha: isDark ? 0.18 : 0.12)
            : context.surfaceColor);

    final borderColor = !hasUrl
        ? context.borderColor
        : (emphasize ? ModuleColors.market : context.borderColor);

    final fg = !hasUrl
        ? context.textTertiary
        : (emphasize ? ModuleColors.market : context.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasUrl ? () => _launchUrl(url) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (hasUrl)
                Icon(Icons.open_in_new_rounded, size: 16, color: fg)
              else
                Text(
                  'Not available',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
