import 'package:flutter/material.dart';

import 'package:am_design_system/am_design_system.dart';
import '../../../internal/domain/entities/filter_criteria.dart';
import '../../../internal/domain/enums/derivative_types.dart';
import '../../../internal/domain/enums/index_types.dart';
import '../../../internal/domain/enums/market_segments.dart';
import 'filter_group.dart';

/// Instrument Filter Group
class InstrumentFilterGroup extends FilterGroup {
  InstrumentFilterGroup({required this.onChanged});
  List<MarketSegments> selectedSegments = [];
  List<IndexTypes> selectedIndexTypes = [];
  List<DerivativeTypes> selectedDerivativeTypes = [];
  final TextEditingController symbolsController = TextEditingController();
  final VoidCallback onChanged;

  @override
  String get title => 'Instrument';

  @override
  IconData get icon => Icons.analytics_outlined;

  @override
  bool get hasActiveFilters =>
      selectedSegments.isNotEmpty ||
      selectedIndexTypes.isNotEmpty ||
      selectedDerivativeTypes.isNotEmpty ||
      symbolsController.text.isNotEmpty;

  @override
  void reset() {
    selectedSegments.clear();
    selectedIndexTypes.clear();
    selectedDerivativeTypes.clear();
    symbolsController.clear();
    onChanged();
  }

  @override
  Widget buildContent(BuildContext context) => Column(
    children: [
      // All three dropdowns in one compact row
      Row(
        children: [
          Expanded(
            child: MultiSelectDropdown<MarketSegments>(
              label: 'Market Segments',
              selectedValues: selectedSegments,
              allValues: MarketSegments.values,
              formatter: _formatMarketSegment,
              onChanged: (values) {
                selectedSegments = values;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MultiSelectDropdown<IndexTypes>(
              label: 'Index Types',
              selectedValues: selectedIndexTypes,
              allValues: IndexTypes.values,
              formatter: _formatIndexType,
              onChanged: (values) {
                selectedIndexTypes = values;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MultiSelectDropdown<DerivativeTypes>(
              label: 'Derivative Types',
              selectedValues: selectedDerivativeTypes,
              allValues: DerivativeTypes.values,
              formatter: _formatDerivativeType,
              onChanged: (values) {
                selectedDerivativeTypes = values;
                onChanged();
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 40,
        child: TextField(
          controller: symbolsController,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            labelText: 'Symbols (comma-separated)',
            labelStyle: const TextStyle(fontSize: 10),
            hintText: 'NIFTY, BANKNIFTY, RELIANCE',
            hintStyle: const TextStyle(fontSize: 9),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            suffixIcon: symbolsController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      symbolsController.clear();
                      onChanged();
                    },
                  )
                : null,
            isDense: true,
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
    ],
  );

  String _formatMarketSegment(MarketSegments segment) {
    switch (segment) {
      case MarketSegments.equity:
        return 'Equity';
      case MarketSegments.indexSegment:
        return 'Index';
      case MarketSegments.equityFutures:
        return 'Equity Futures';
      case MarketSegments.indexFutures:
        return 'Index Futures';
      case MarketSegments.equityOptions:
        return 'Equity Options';
      case MarketSegments.indexOptions:
        return 'Index Options';
      case MarketSegments.unknown:
        return 'Unknown';
    }
  }

  String _formatIndexType(IndexTypes type) {
    switch (type) {
      case IndexTypes.nifty:
        return 'NIFTY';
      case IndexTypes.banknifty:
        return 'BANKNIFTY';
      case IndexTypes.finnifty:
        return 'FINNIFTY';
      case IndexTypes.midcpnifty:
        return 'MIDCPNIFTY';
    }
  }

  String _formatDerivativeType(DerivativeTypes type) {
    switch (type) {
      case DerivativeTypes.futures:
        return 'Futures';
      case DerivativeTypes.options:
        return 'Options';
    }
  }

  InstrumentFilterCriteria toFilterCriteria() => InstrumentFilterCriteria(
    marketSegments: selectedSegments,
    indexTypes: selectedIndexTypes,
    derivativeTypes: selectedDerivativeTypes,
    baseSymbols: symbolsController.text.isEmpty
        ? []
        : symbolsController.text.split(',').map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).toList(),
  );

  void dispose() {
    symbolsController.dispose();
  }
}
