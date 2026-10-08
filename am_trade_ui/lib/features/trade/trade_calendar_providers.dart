import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/cubit/trade_calendar_cubit.dart';
import 'providers/trade_internal_providers.dart';
import 'trade_controller_providers.dart';

/// Provider for TradeCalendarCubit
final tradeCalendarCubitProvider = FutureProvider.family<TradeCalendarCubit, String>((
  ref,
  portfolioId,
) async {
  final getTradeCalendar = await ref.watch(getTradeCalendarProvider.future);
  final getTradeCalendarByMonth = await ref.watch(getTradeCalendarByMonthProvider.future);
  final getTradeCalendarByDay = await ref.watch(getTradeCalendarByDayProvider.future);
  final getTradeCalendarByDateRange = await ref.watch(getTradeCalendarByDateRangeProvider.future);

  final cubit = TradeCalendarCubit(
    getTradeCalendar,
    getTradeCalendarByMonth,
    getTradeCalendarByDay,
    getTradeCalendarByDateRange,
  );

  // Industry-standard reactive pattern: Listen to the trades stream for this portfolio.
  // Whenever the trade details are updated (via add/edit/delete or WebSockets),
  // this listener will automatically refresh the calendar data to stay perfectly in sync.
  ref.listen(watchTradesByPortfolioProvider(portfolioId), (previous, next) {
    // Only refresh if we have valid new data and the lists are referentially different
    if (next.hasValue && previous?.value != next.value) {
      // Only refresh if the calendar is already loaded to prevent unwanted API calls
      // on calendar init
      if (cubit.isLoaded) {
        cubit.refresh(portfolioId: portfolioId, forceReload: true);
      }
    }
  });

  // Ensure cubit is properly closed when provider is disposed
  ref.onDispose(() => cubit.close());

  return cubit;
});
