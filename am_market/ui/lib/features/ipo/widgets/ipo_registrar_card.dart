import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IpoRegistrarCard extends StatelessWidget {
  final AsraxIpoRegistrarDto? registrar;

  const IpoRegistrarCard({super.key, required this.registrar});

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
              Icon(Icons.people_alt_outlined, size: 18, color: ModuleColors.market),
              const SizedBox(width: 8),
              Text(
                'Registrar Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildRow(
            context,
            label: 'Name',
            value: registrar?.name ?? 'N/A',
          ),
          const SizedBox(height: 12),

          _buildRow(
            context,
            label: 'Contact Person',
            value: registrar?.contactName ?? 'N/A',
          ),
          const SizedBox(height: 12),

          _buildClickableRow(
            context,
            label: 'Email',
            value: registrar?.email ?? 'N/A',
            icon: Icons.mail_outline_rounded,
            onTap: registrar?.email != null ? () => _launch('mailto:${registrar!.email}') : null,
          ),
          const SizedBox(height: 12),

          _buildClickableRow(
            context,
            label: 'Contact Number',
            value: registrar?.phone ?? 'N/A',
            icon: Icons.phone_outlined,
            onTap: registrar?.phone != null ? () => _launch('tel:${registrar!.phone}') : null,
          ),
          const SizedBox(height: 12),

          _buildClickableRow(
            context,
            label: 'Website',
            value: registrar?.websiteUrl ?? 'N/A',
            icon: Icons.open_in_new_rounded,
            onTap: registrar?.websiteUrl != null ? () => _launch(registrar!.websiteUrl!) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isLink = onTap != null && value != 'N/A';
    final accentColor = ModuleColors.market;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLink) ...[
                  Icon(icon, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isLink ? accentColor : context.textPrimary,
                      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
