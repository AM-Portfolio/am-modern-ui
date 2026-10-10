import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IpoDocumentsCard extends StatelessWidget {
  final String? rhpUrl;
  final String? drhpUrl;

  const IpoDocumentsCard({super.key, this.rhpUrl, this.drhpUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.description_outlined,
                  size: 18, color: ModuleColors.market),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. RHP PDF Button (Vibrant Green CTA)
          _buildRhpButton(context),
          const SizedBox(height: 12),

          // 2. DRHP PDF Button
          _buildDrhpButton(context),
          const SizedBox(height: 16),

          // 3. Advisory Note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: context.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Read the official RHP for detailed information before investing.',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildRhpButton(BuildContext context) {
    final hasRhp = rhpUrl != null && rhpUrl!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: hasRhp ? () => _launchUrl(rhpUrl!) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: hasRhp ? context.colors.statusSuccess : (context.surfaceColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: hasRhp
              ? [
                  BoxShadow(
                    color: context.colors.statusSuccess.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.textPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'RHP PDF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (hasRhp)
              const Icon(Icons.open_in_new_rounded,
                  size: 18, color: Colors.white)
            else
              Text(
                'Not available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrhpButton(BuildContext context) {
    final hasDrhp = drhpUrl != null && drhpUrl!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: hasDrhp ? () => _launchUrl(drhpUrl!) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? context.surfaceColor.withValues(alpha: 0.5)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? context.dividerColor : context.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 18,
              color: hasDrhp ? context.textPrimary : context.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'DRHP PDF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasDrhp ? context.textPrimary : context.textSecondary,
                ),
              ),
            ),
            if (hasDrhp)
              Icon(Icons.open_in_new_rounded,
                  size: 16, color: context.textPrimary)
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
