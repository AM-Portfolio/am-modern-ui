import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter/material.dart';

class IpoTimelineStepper extends StatelessWidget {
  final AsraxIpoTimelineDto? timeline;
  final String? dailyStartTime;
  final String? dailyEndTime;
  final String? listingExchange;

  const IpoTimelineStepper({
    super.key,
    required this.timeline,
    this.dailyStartTime,
    this.dailyEndTime,
    this.listingExchange,
  });

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AmBreakpoints.mobile;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 22),
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
                Icons.calendar_month_outlined,
                size: 18,
                color: ModuleColors.market,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Dates',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 24),
          if (isCompact)
            _buildVerticalTimeline(context, stages)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(stages.length, (index) {
                    final stage = stages[index];
                    final isLast = index == stages.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStageNode(context, stage),
                        if (!isLast)
                          _buildConnectorLine(context, stage.isCompleted),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalTimeline(
    BuildContext context,
    List<_TimelineStage> stages,
  ) {
    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isLast = index == stages.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    _buildVerticalMarker(context, stage),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: stage.isCompleted || stage.isActive
                              ? ModuleColors.market
                              : context.dividerColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: stage.isActive || stage.isCompleted
                                    ? context.textPrimary
                                    : context.textSecondary,
                              ),
                            ),
                            if (stage.subtitle != null &&
                                stage.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                stage.subtitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stage.date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              stage.isActive ? FontWeight.w700 : FontWeight.w500,
                          color: stage.isActive
                              ? ModuleColors.market
                              : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerticalMarker(BuildContext context, _TimelineStage stage) {
    if (stage.isCompleted) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: ModuleColors.market,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 11, color: Colors.white),
      );
    }
    if (stage.isActive) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: ModuleColors.market.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: ModuleColors.market, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ModuleColors.market,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: context.dividerColor, width: 1.5),
      ),
    );
  }

  Widget _buildStageNode(BuildContext context, _TimelineStage stage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget indicator;
    if (stage.isCompleted) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: context.colors.statusSuccess,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    } else if (stage.isActive) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: ModuleColors.market.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: ModuleColors.market, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: ModuleColors.market,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? context.dividerColor : context.borderColor,
            width: 2,
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            stage.date,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: stage.isActive ? FontWeight.w700 : FontWeight.w500,
              color:
                  stage.isActive ? ModuleColors.market : context.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stage.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: stage.isActive || stage.isCompleted
                  ? context.textPrimary
                  : context.textSecondary,
            ),
          ),
          if (stage.subtitle != null && stage.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              stage.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectorLine(BuildContext context, bool isCompleted) {
    return Container(
      width: 44,
      height: 2,
      margin: const EdgeInsets.only(top: 12),
      color: isCompleted
          ? context.colors.statusSuccess
          : context.dividerColor,
    );
  }

  List<_TimelineStage> _buildStages() {
    final now = DateTime.now();

    final preApply = timeline?.preApplyStartDate;
    final appStart = timeline?.applicationStartDate;
    final appEnd = timeline?.applicationEndDate;
    final allotStart = timeline?.allotmentStartDate;
    final allotDate = timeline?.allotmentDate;
    final refund = timeline?.refundInitiationDate;
    final listing = timeline?.listingDate;
    final mandate = timeline?.mandateEndDate;

    return [
      _createStage('Pre-Apply Start', preApply, '(Optional)', now),
      _createStage(
        'Application Start',
        appStart,
        _formatTime(dailyStartTime, '10:00 AM'),
        now,
      ),
      _createStage(
        'Application End',
        appEnd,
        _formatTime(dailyEndTime, '5:00 PM'),
        now,
      ),
      _createStage('Allotment Start', allotStart, null, now),
      _createStage('Allotment Date', allotDate, null, now),
      _createStage('Refund Initiation', refund, null, now),
      _createStage('Listing Date', listing, listingExchange ?? 'BSE', now),
      _createStage('Mandate End', mandate, '(Auto UPI)', now),
    ];
  }

  _TimelineStage _createStage(
    String title,
    String? dateStr,
    String? subtitle,
    DateTime now,
  ) {
    if (dateStr == null || dateStr.isEmpty) {
      return _TimelineStage(
        title: title,
        date: 'TBA',
        subtitle: subtitle,
        isCompleted: false,
        isActive: false,
      );
    }

    try {
      final date = DateTime.parse(dateStr);
      final isCompleted = now.isAfter(date);
      final isToday = now.year == date.year &&
          now.month == date.month &&
          now.day == date.day;

      return _TimelineStage(
        title: title,
        date: _formatDate(date),
        subtitle: subtitle,
        isCompleted: isCompleted && !isToday,
        isActive: isToday,
      );
    } catch (_) {
      return _TimelineStage(
        title: title,
        date: dateStr,
        subtitle: subtitle,
        isCompleted: false,
        isActive: false,
      );
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String? timeStr, String fallback) {
    if (timeStr == null || timeStr.isEmpty) return fallback;
    return timeStr.substring(0, timeStr.length.clamp(0, 5));
  }
}

class _TimelineStage {
  final String title;
  final String date;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;

  const _TimelineStage({
    required this.title,
    required this.date,
    this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });
}
