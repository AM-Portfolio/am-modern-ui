import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/cubit/trade_calendar_cubit.dart';
import 'providers/trade_internal_providers.dart';

/// Provider for TradeCalendarCubit
final tradeCalendarCubitProvider = FutureProvider.family<TradeCalendarCubit, ({String userId, String portfolioId})>((
  ref,
  params,
) async {
  final getTradeCalendar = await ref.watch(getTradeCalendarProvider.future);
  final getTradeCalendarByMonth = await ref.watch(getTradeCalendarByMonthProvider.future);
  final getTradeCalendarByDay = await ref.watch(getTradeCalendarByDayProvider.future);
  final getTradeCalendarByDateRange = await ref.watch(getTradeCalendarByDateRangeProvider.future);

  return TradeCalendarCubit(
    getTradeCalendar,
    getTradeCalendarByMonth,
    getTradeCalendarByDay,
    getTradeCalendarByDateRange,
  );
});
