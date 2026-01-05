import 'package:flutter/material.dart';

import '../../../../../features/trade/internal/domain/enums/exchange_types.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import '../../../../../features/trade/internal/domain/enums/market_segments.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import 'package:am_design_system/am_design_system.dart';

/// Instrument details card for trade forms
class InstrumentCard extends StatelessWidget {
  const InstrumentCard({
    required this.symbolController,
    required this.selectedExchange,
    required this.selectedSegment,
    required this.onExchangeChanged,
    required this.onSegmentChanged,
    super.key,
  });

  final TextEditingController symbolController;
  final ExchangeTypes? selectedExchange;
  final MarketSegments? selectedSegment;
  final ValueChanged<ExchangeTypes?> onExchangeChanged;
  final ValueChanged<MarketSegments?> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.candlestick_chart, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Instrument',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          TextField(
            controller: symbolController,
            decoration: InputDecoration(
              labelText: 'Symbol *',
              hintText: 'e.g., RELIANCE',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          CustomDropdown<ExchangeTypes>(
            value: selectedExchange,
            hint: 'Select Exchange',
            items: ExchangeTypes.values
                .map(
                  (exchange) => exchange.toSimpleDropdownItem(text: exchange.toString().split('.').last.toUpperCase()),
                )
                .toList(),
            onChanged: onExchangeChanged,
            icon: Icons.account_balance,
          ),
          CustomDropdown<MarketSegments>(
            value: selectedSegment,
            hint: 'Select Segment',
            items: MarketSegments.values
                .map((segment) => segment.toSimpleDropdownItem(text: segment.toString().split('.').last.toUpperCase()))
                .toList(),
            onChanged: onSegmentChanged,
            icon: Icons.pie_chart,
          ),
        ],
      ),
    );
  }
}
