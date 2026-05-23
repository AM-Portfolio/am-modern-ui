import 'package:flutter/material.dart';

import '../../../../models/trade_holding_view_model.dart';
import '../widgets/trade_overview_selector.dart';

class JournalTradeSection extends StatelessWidget {
  const JournalTradeSection({
    required this.selectedDate,
    required this.selectedPeriod,
    required this.selectedTradeIds,
    required this.availableTrades,
    required this.isEditMode,
    required this.onDateChanged,
    required this.onPeriodChanged,
    required this.onTradesSelected,
    required this.onViewTrades,
    super.key,
  });

  final DateTime selectedDate;
  final TradePeriodType selectedPeriod;
  final List<String> selectedTradeIds;
  final List<TradeHoldingViewModel> availableTrades;
  final bool isEditMode;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TradePeriodType> onPeriodChanged;
  final ValueChanged<List<String>> onTradesSelected;
  final VoidCallback onViewTrades;

  @override
  Widget build(BuildContext context) => TradeOverviewSelector(
    selectedDate: selectedDate,
    selectedPeriod: selectedPeriod,
    selectedTradeIds: selectedTradeIds,
    availableTrades: availableTrades,
    onDateChanged: onDateChanged,
    onPeriodChanged: onPeriodChanged,
    onTradesSelected: onTradesSelected,
    onViewTrades: onViewTrades,
    readOnly: !isEditMode,
  );
}

