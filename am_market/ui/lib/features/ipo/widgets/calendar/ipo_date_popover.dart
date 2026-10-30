import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_calendar_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_calendar_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoDatePopover extends ConsumerWidget {
  final List<IpoCalendarEntryDto> events;
  final List<String> sortedEventDates;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseLeave;

  const IpoDatePopover({
    super.key,
    required this.events,
    required this.sortedEventDates,
    required this.onMouseEnter,
    required this.onMouseLeave,
  });

  String _formatDate(String? dateKey) {
    if (dateKey == null) return '';
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final dt = DateTime(year, month, day);
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayName = days[dt.weekday - 1];
        return '$dayName, $day ${months[month - 1]} $year';
      }
    } catch (_) {}
    return dateKey;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(ipoCalendarUiProvider);
    final uiNotifier = ref.read(ipoCalendarUiProvider.notifier);

    final pageCount = (events.length / 2).ceil().clamp(1, 99);
    final currentPage = uiState.eventPage.clamp(0, pageCount - 1);
    final start = currentPage * 2;
    final visibleEvents = events.skip(start).take(2).toList();

    final currentIndex = uiState.activeDateKey != null
        ? sortedEventDates.indexOf(uiState.activeDateKey!)
        : -1;
    final hasPrevDate = currentIndex > 0;
    final hasNextDate =
        currentIndex >= 0 && currentIndex < sortedEventDates.length - 1;

    final formattedDate = _formatDate(uiState.activeDateKey);

    return MouseRegion(
      onEnter: (_) => onMouseEnter(),
      onExit: (_) => onMouseLeave(),
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            if (pointerSignal.scrollDelta.dy > 0) {
              if (currentPage < pageCount - 1) {
                uiNotifier.setEventPage(currentPage + 1);
              }
            } else if (pointerSignal.scrollDelta.dy < 0) {
              if (currentPage > 0) {
                uiNotifier.setEventPage(currentPage - 1);
              }
            }
          }
        },
        child: Container(
          width: 252,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top header: Formatted date, listing count badge, and scroll hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (formattedDate.isNotEmpty)
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: ModuleColors.market,
                              letterSpacing: 0.3,
                            ),
                          ),
                        const SizedBox(height: 1),
                        Text(
                          '${events.length} IPO listing${events.length > 1 ? "s" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pageCount > 1)
                    Text(
                      '< scroll to browse >',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: ModuleColors.market,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // Event cards (at most 2 visible)
              ...visibleEvents.asMap().entries.map((entry) {
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildIpoCard(context, item),
                );
              }),

              const SizedBox(height: 4),

              // Bottom controls: Previous, page indicator pill dots, Next
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavButton(
                    context,
                    label: '< Previous',
                    enabled: currentPage > 0 || hasPrevDate,
                    onTap: () {
                      if (currentPage > 0) {
                        uiNotifier.setEventPage(currentPage - 1);
                      } else if (hasPrevDate) {
                        uiNotifier.switchDate(-1, sortedEventDates);
                      }
                    },
                  ),

                  // Centered page dots (active is a pill)
                  if (pageCount > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(pageCount, (dotIndex) {
                        final isActive = dotIndex == currentPage;
                        return InkWell(
                          onTap: () => uiNotifier.setEventPage(dotIndex),
                          borderRadius: BorderRadius.circular(3),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 3,
                            ),
                            child: Container(
                              width: isActive ? 14 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.5),
                                color: isActive
                                    ? ModuleColors.market
                                    : context.borderColor,
                              ),
                            ),
                          ),
                        );
                      }),
                    )
                  else
                    const SizedBox(width: 8),

                  _buildNavButton(
                    context,
                    label: 'Next >',
                    enabled: currentPage < pageCount - 1 || hasNextDate,
                    onTap: () {
                      if (currentPage < pageCount - 1) {
                        uiNotifier.setEventPage(currentPage + 1);
                      } else if (hasNextDate) {
                        uiNotifier.switchDate(1, sortedEventDates);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIpoCard(BuildContext context, IpoCalendarEntryDto item) {
    final isListed = item.status == IpoCalendarDisplayStatus.listed;
    final statusColor = isListed
        ? context.colors.statusSuccess
        : context.colors.statusWarning;

    final priceText = item.listingPrice != null
        ? '₹${item.listingPrice!.toStringAsFixed(item.listingPrice!.truncateToDouble() == item.listingPrice! ? 0 : 2)}'
        : 'TBA';
    final exchangeText = item.listingExchange?.isNotEmpty == true
        ? item.listingExchange!
        : 'TBA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Company Name & Status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  item.companyName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ModuleColors.market,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // 2-column fields in dark card box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Listing price',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: context.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.listingPrice != null
                              ? context.textPrimary
                              : context.colors.statusWarning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Listed on',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: context.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        exchangeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.listingExchange?.isNotEmpty == true
                              ? context.textPrimary
                              : context.colors.statusWarning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String label,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: enabled ? context.surfaceColor : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: enabled
                ? context.borderColor
                : context.borderColor.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: enabled ? context.textSecondary : context.textTertiary,
          ),
        ),
      ),
    );
  }
}
