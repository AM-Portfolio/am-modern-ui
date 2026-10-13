import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/screens/ipo_details_screen.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_board_badge.dart';
import 'package:am_market_ui/features/ipo/widgets/subscription_progress_bar.dart';
import 'package:flutter/material.dart';

class IpoSummaryCard extends StatelessWidget {
  final AsraxIpoSummaryDto ipo;
  final bool compact;

  const IpoSummaryCard({
    super.key,
    required this.ipo,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Ink(
          padding: EdgeInsets.all(compact ? 10 : 18),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.textPrimary
                    .withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: compact ? 6 : 10,
                offset: Offset(0, compact ? 2 : 4),
              ),
            ],
          ),
          child: compact
              ? _buildCompactBody(context)
              : _buildDesktopBody(context),
        ),
      ),
    );
  }

  Widget _buildCompactBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(context, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ipo.companyName ?? 'Unknown Company',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (ipo.symbol != null && ipo.symbol!.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            ipo.symbol!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textTertiary,
                          ),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          _boardLabel(ipo.issueType),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _buildStatusBadge(context),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Price Band',
                value: _formatPriceBand(ipo.minimumPrice, ipo.maximumPrice),
              ),
            ),
            _metricDivider(context),
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Issue Size',
                value: _formatIssueSize(ipo.issueSizeCr),
                alignCenter: true,
              ),
            ),
            _metricDivider(context),
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Bidding Opens',
                value: _formatDate(ipo.biddingStartDate),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(context, size: 42),
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
        SubscriptionProgressBar(subscriptionStr: ipo.totalSubscription),
        const SizedBox(height: 14),
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
                const SizedBox(width: 6),
                Text(
                  'View IPO Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ModuleColors.market,
                  ),
                ),
                const SizedBox(width: 4),
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
    );
  }

  Widget _metricDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: context.dividerColor.withValues(alpha: 0.7),
    );
  }

  void _openDetails(BuildContext context) {
    // Nearest navigator is IpoCenterHost when embedded in Market — keeps
    // module pills / sidebar visible. Standalone falls back to root nav.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => IpoDetailsScreen(
          ipoId: ipo.id,
          embedded: true,
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required double size}) {
    final initials = _getInitials(ipo.companyName ?? ipo.symbol ?? 'IP');
    final avatarColor = IpoColors.avatarColorFor(initials);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size >= 40 ? 10 : 8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size >= 40 ? 14 : 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.5,
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
    bool alignCenter = false,
    bool alignEnd = false,
  }) {
    final align = alignEnd
        ? CrossAxisAlignment.end
        : (alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start);
    final textAlign =
        alignEnd ? TextAlign.end : (alignCenter ? TextAlign.center : TextAlign.start);

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
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

  String _boardLabel(String? issueType) {
    final t = (issueType ?? '').toLowerCase();
    if (t.contains('sme')) return 'SME';
    return 'Mainboard';
  }

  String _getInitials(String name) {
    final clean = name
        .replaceAll(RegExp(r'(IPO|Limited|Ltd|\.)', caseSensitive: false), '')
        .trim();
    final parts =
        clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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

  String _formatIssueSize(double? size) {
    if (size == null) return '₹--';
    return '₹${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} Cr';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBA';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
