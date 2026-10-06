import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_board_badge.dart';
import 'package:flutter/material.dart';

class IpoOverviewHeaderCard extends StatelessWidget {
  final AsraxIpoDetailsDto ipo;

  const IpoOverviewHeaderCard({super.key, required this.ipo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : context.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Avatar/Logo, Title/Badges, Status + Countdown
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final leftSection = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ipo.companyName ?? 'IPO Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLegalName(ipo.companyName),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (ipo.symbol != null && ipo.symbol!.isNotEmpty)
                              _buildTag(context, ipo.symbol!),
                            IpoBoardBadge(issueType: ipo.issueType),
                            if (ipo.industry != null && ipo.industry!.isNotEmpty)
                              _buildTag(context, ipo.industry!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final rightSection = _buildCountdownSection(context);

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftSection,
                    const SizedBox(height: 16),
                    rightSection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftSection),
                  const SizedBox(width: 16),
                  rightSection,
                ],
              );
            },
          ),

          const SizedBox(height: 22),
          Divider(color: isDark ? const Color(0xFF1E293B) : context.borderColor),
          const SizedBox(height: 16),

          // 2. 7-Parameter Key Metrics Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              final items = [
                _buildParamItem(
                  context,
                  icon: Icons.local_offer_outlined,
                  label: 'Price Band',
                  value: _formatPriceBand(ipo.minimumPrice, ipo.maximumPrice),
                ),
                _buildParamItem(
                  context,
                  icon: Icons.layers_outlined,
                  label: 'Issue Size',
                  value: _formatIssueSize(ipo.issueSizeCr),
                ),
                _buildParamItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Lot Size',
                  value: ipo.lotSize != null ? '${ipo.lotSize} shares' : 'TBA',
                ),
                _buildParamItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Min. Quantity',
                  value: ipo.minimumQuantity != null
                      ? '${ipo.minimumQuantity} shares'
                      : (ipo.lotSize != null ? '${ipo.lotSize} shares' : 'TBA'),
                ),
                _buildParamItem(
                  context,
                  icon: Icons.lock_outline_rounded,
                  label: 'Cut-off Price',
                  value: ipo.cutOffPrice != null ? '₹${ipo.cutOffPrice!.toStringAsFixed(0)}' : '₹--',
                ),
                _buildParamItem(
                  context,
                  icon: Icons.currency_rupee_rounded,
                  label: 'Face Value',
                  value: ipo.faceValue != null ? '₹${ipo.faceValue!.toStringAsFixed(0)}' : '₹--',
                ),
                _buildParamItem(
                  context,
                  icon: Icons.account_balance_outlined,
                  label: 'Listing Exchange',
                  value: ipo.listingExchange ?? 'BSE',
                ),
              ];

              if (!isWide) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: items.map((w) => SizedBox(width: 140, child: w)).toList(),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.map((w) => Expanded(child: w)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(ipo.companyName ?? ipo.symbol ?? 'IP');

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : context.borderColor,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCountdownSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (ipo.status ?? 'OPEN').toUpperCase();
    final remainingDays = _calculateRemainingDays(ipo.biddingEndDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF052E16).withValues(alpha: 0.6) : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.5) : const Color(0xFF86EFAC),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22C55E),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bidding closes in',
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          remainingDays,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF22C55E),
          ),
        ),
        if (ipo.biddingEndDate != null && ipo.biddingEndDate!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '(${_formatShortDate(ipo.biddingEndDate!)})',
            style: TextStyle(
              fontSize: 11,
              color: context.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParamItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: context.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.textTertiary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getLegalName(String? name) {
    if (name == null || name.isEmpty) return 'Company Limited';
    if (!name.toLowerCase().contains('limited') && !name.toLowerCase().contains('ltd')) {
      return '$name Limited';
    }
    return name;
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'(IPO|Limited|Ltd|\.)', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'IP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 3)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatPriceBand(double? min, double? max) {
    if (min == null && max == null) return '₹--';
    if (min != null && max != null) {
      if (min == max) return '₹${min.toStringAsFixed(0)}';
      return '₹${min.toStringAsFixed(0)} – ₹${max.toStringAsFixed(0)}';
    }
    final single = min ?? max;
    return '₹${single?.toStringAsFixed(0)}';
  }

  String _formatIssueSize(double? size) {
    if (size == null) return '₹--';
    return '₹${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} Cr';
  }

  String _calculateRemainingDays(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBA';
    try {
      final end = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = end.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff < 0) return 'Closed';
      if (diff == 0) return 'Today';
      if (diff == 1) return '1 day';
      return '$diff days';
    } catch (_) {
      return 'TBA';
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
