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
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : context.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'View IPO Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
    final colorPair = _getAvatarColor(initials);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorPair.background,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colorPair.foreground,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = (ipo.status ?? 'OPEN').toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    if (status == 'OPEN') {
      bg = isDark ? const Color(0xFF052E16).withValues(alpha: 0.6) : const Color(0xFFDCFCE7);
      fg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      border = isDark ? const Color(0xFF16A34A).withValues(alpha: 0.5) : const Color(0xFF86EFAC);
    } else if (status == 'UPCOMING') {
      bg = isDark ? const Color(0xFF451A03).withValues(alpha: 0.6) : const Color(0xFFFEF3C7);
      fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      border = isDark ? const Color(0xFFD97706).withValues(alpha: 0.5) : const Color(0xFFFCD34D);
    } else {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      fg = context.textSecondary;
      border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    }

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

  _AvatarColors _getAvatarColor(String initials) {
    final colors = [
      const _AvatarColors(Color(0xFFE0F2FE), Color(0xFF0369A1)), // Sky Blue
      const _AvatarColors(Color(0xFFDCFCE7), Color(0xFF15803D)), // Green
      const _AvatarColors(Color(0xFFFEF3C7), Color(0xFFB45309)), // Yellow
      const _AvatarColors(Color(0xFFF3E8FF), Color(0xFF7E22CE)), // Purple
      const _AvatarColors(Color(0xFFFFE4E6), Color(0xFFBE123C)), // Rose
      const _AvatarColors(Color(0xFFCCFBF1), Color(0xFF0F766E)), // Teal
    ];
    final hash = initials.hashCode.abs();
    return colors[hash % colors.length];
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

class _AvatarColors {
  final Color background;
  final Color foreground;
  const _AvatarColors(this.background, this.foreground);
}
