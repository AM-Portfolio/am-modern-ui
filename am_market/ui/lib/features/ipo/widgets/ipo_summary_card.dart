import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/screens/ipo_details_screen.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_board_badge.dart';
import 'package:am_market_ui/features/ipo/widgets/subscription_progress_bar.dart';
import 'package:flutter/material.dart';

class IpoSummaryCard extends StatelessWidget {
  final AsraxIpoSummaryDto ipo;

  const IpoSummaryCard({super.key, required this.ipo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.textPrimary.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Avatar, Name, Symbol + Board, Status)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ipo.companyName ?? 'Unknown Company',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (ipo.symbol != null && ipo.symbol!.isNotEmpty) ...[
                            Text(
                              ipo.symbol!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IpoBoardBadge(issueType: ipo.issueType),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 18),

            // 2. 3-Column Metrics (Price Band, Issue Size, Industry)
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    label: 'Price Band',
                    value: _formatPriceBand(ipo.minimumPrice, ipo.maximumPrice),
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    label: 'Issue Size',
                    value: _formatIssueSize(ipo.issueSizeCr),
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    label: 'Industry',
                    value: ipo.industry ?? 'General',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. 2-Column Bidding Dates (Opens, Closes)
            Row(
              children: [
                Expanded(
                  child: _buildDateItem(
                    context,
                    label: 'Bidding Opens',
                    dateStr: ipo.biddingStartDate,
                  ),
                ),
                Expanded(
                  child: _buildDateItem(
                    context,
                    label: 'Bidding Closes',
                    dateStr: ipo.biddingEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Subscription Progress Bar
            SubscriptionProgressBar(subscriptionStr: ipo.totalSubscription),
            const SizedBox(height: 14),

            // 5. Card Footer Action
            InkWell(
              onTap: () => _openDetails(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 15,
                      color: ModuleColors.market,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'View IPO Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ModuleColors.market,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: ModuleColors.market,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IpoDetailsScreen(ipoId: ipo.id),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final initials = _getInitials(ipo.companyName ?? ipo.symbol ?? 'IP');
    final avatarColor = IpoColors.avatarColorFor(initials);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: avatarColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = (ipo.status ?? 'OPEN').toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color fg;
    if (status == 'OPEN') {
      fg = context.colors.statusSuccess;
    } else if (status == 'UPCOMING') {
      fg = context.colors.statusWarning;
    } else {
      fg = context.colors.statusError;
    }

    final bg = fg.withValues(alpha: isDark ? 0.18 : 0.12);
    final border = fg.withValues(alpha: isDark ? 0.45 : 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDateItem(
    BuildContext context, {
    required String label,
    required String? dateStr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              _formatDate(dateStr),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: context.textTertiary,
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'(IPO|Limited|Ltd|\.)', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'IP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
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

  String _formatMinInvestment(double? amount) {
    if (amount == null || amount <= 0) return '₹--';
    final intVal = amount.round();
    final s = intVal.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    return '₹${chunks.join(',')},$last3';
  }

  String _formatIssueSize(double? size) {
    if (size == null) return '₹--';
    return '₹${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} Cr';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBA';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
