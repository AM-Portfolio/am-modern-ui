import 'package:flutter/material.dart';

import '../../../../../shared/core/ui/components/trade/derivative_card.dart';
import '../../../../../shared/core/ui/components/trade/direction_status_selector.dart';
import '../../../../../shared/core/ui/components/trade/entry_exit_card.dart';
import '../../../../../shared/core/ui/components/trade/instrument_card.dart';
import '../../../../../shared/core/ui/components/trade/trade_settings_card.dart';
import '../widgets/trade_attachment_section.dart';
import '../../../internal/domain/enums/broker_types.dart';
import '../../../internal/domain/enums/derivative_types.dart';
import '../../../internal/domain/enums/exchange_types.dart';
import '../../../internal/domain/enums/market_segments.dart';
import '../../../internal/domain/enums/option_types.dart';
import '../../../internal/domain/enums/order_types.dart';
import '../../../internal/domain/enums/trade_directions.dart';
import '../../../internal/domain/enums/trade_statuses.dart';

/// Trade Details Step - Combined Instrument + Entry/Exit
class TradeDetailsStep extends StatelessWidget {
  const TradeDetailsStep({
    required this.symbolController,
    required this.selectedExchange,
    required this.selectedSegment,
    required this.selectedDirection,
    required this.selectedStatus,
    required this.entryDate,
    required this.entryPriceController,
    required this.entryQuantityController,
    required this.exitDate,
    required this.exitPriceController,
    required this.exitQuantityController,
    required this.selectedBroker,
    required this.selectedOrderType,
    required this.selectedDerivativeType,
    required this.selectedOptionType,
    required this.strikePriceController,
    required this.expiryDate,
    required this.attachments,
    required this.onExchangeChanged,
    required this.onSegmentChanged,
    required this.onDirectionChanged,
    required this.onStatusChanged,
    required this.onEntryDateSelected,
    required this.onExitDateSelected,
    required this.onBrokerChanged,
    required this.onOrderTypeChanged,
    required this.onDerivativeTypeChanged,
    required this.onOptionTypeChanged,
    required this.onExpiryDateSelected,
    required this.onAttachmentsChanged,
    this.userId,
    this.onInstrumentSelected,
    super.key,
  });

  final TextEditingController symbolController;
  final ExchangeTypes? selectedExchange;
  final MarketSegments? selectedSegment;
  final TradeDirections selectedDirection;
  final TradeStatuses selectedStatus;
  final DateTime? entryDate;
  final TextEditingController entryPriceController;
  final TextEditingController entryQuantityController;
  final DateTime? exitDate;
  final TextEditingController exitPriceController;
  final TextEditingController exitQuantityController;
  final BrokerTypes? selectedBroker;
  final OrderTypes? selectedOrderType;
  final DerivativeTypes? selectedDerivativeType;
  final OptionTypes? selectedOptionType;
  final TextEditingController strikePriceController;
  final DateTime? expiryDate;
  final List<String> attachments;
  final String? userId;
  final ValueChanged<Map<String, dynamic>>? onInstrumentSelected;

  final ValueChanged<ExchangeTypes?> onExchangeChanged;
  final ValueChanged<MarketSegments?> onSegmentChanged;
  final ValueChanged<TradeDirections> onDirectionChanged;
  final ValueChanged<TradeStatuses> onStatusChanged;
  final ValueChanged<DateTime> onEntryDateSelected;
  final ValueChanged<DateTime> onExitDateSelected;
  final ValueChanged<BrokerTypes?> onBrokerChanged;
  final ValueChanged<OrderTypes?> onOrderTypeChanged;
  final ValueChanged<DerivativeTypes?> onDerivativeTypeChanged;
  final ValueChanged<OptionTypes?> onOptionTypeChanged;
  final ValueChanged<DateTime> onExpiryDateSelected;
  final ValueChanged<List<String>> onAttachmentsChanged;

  bool get _isDerivativeSegment =>
      selectedSegment == MarketSegments.equityFutures ||
      selectedSegment == MarketSegments.indexFutures ||
      selectedSegment == MarketSegments.equityOptions ||
      selectedSegment == MarketSegments.indexOptions;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width <= 1200;
    final isWeb = isDesktop || isTablet;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Direction, Status & Trade Settings Row (Web) or Stacked (Mobile)
          if (isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DirectionStatusSelector(
                  selectedDirection: selectedDirection,
                  selectedStatus: selectedStatus,
                  onDirectionChanged: onDirectionChanged,
                  onStatusChanged: onStatusChanged,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TradeSettingsCard(
                    selectedBroker: selectedBroker,
                    selectedOrderType: selectedOrderType,
                    onBrokerChanged: onBrokerChanged,
                    onOrderTypeChanged: onOrderTypeChanged,
                  ),
                ),
              ],
            )
          else ...[
            // Mobile: Keep stacked layout
            DirectionStatusSelector(
              selectedDirection: selectedDirection,
              selectedStatus: selectedStatus,
              onDirectionChanged: onDirectionChanged,
              onStatusChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),
            TradeSettingsCard(
              selectedBroker: selectedBroker,
              selectedOrderType: selectedOrderType,
              onBrokerChanged: onBrokerChanged,
              onOrderTypeChanged: onOrderTypeChanged,
            ),
          ],

          const SizedBox(height: 12),

          // Instrument & Entry/Exit in 2 columns (desktop) or stacked (mobile)
          if (isDesktop || isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InstrumentCard(
                    symbolController: symbolController,
                    selectedExchange: selectedExchange,
                    selectedSegment: selectedSegment,
                    onExchangeChanged: onExchangeChanged,
                    onSegmentChanged: onSegmentChanged,
                    onInstrumentSelected: onInstrumentSelected,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: EntryExitCard(
                    entryDate: entryDate,
                    entryPriceController: entryPriceController,
                    entryQuantityController: entryQuantityController,
                    exitDate: exitDate,
                    exitPriceController: exitPriceController,
                    exitQuantityController: exitQuantityController,
                    onEntryDateChanged: onEntryDateSelected,
                    onExitDateChanged: onExitDateSelected,
                    showExit: selectedStatus != TradeStatuses.open,
                  ),
                ),
              ],
            )
          else ...[
            InstrumentCard(
              symbolController: symbolController,
              selectedExchange: selectedExchange,
              selectedSegment: selectedSegment,
              onExchangeChanged: onExchangeChanged,
              onSegmentChanged: onSegmentChanged,
              onInstrumentSelected: onInstrumentSelected,
            ),
            const SizedBox(height: 12),
            EntryExitCard(
              entryDate: entryDate,
              entryPriceController: entryPriceController,
              entryQuantityController: entryQuantityController,
              exitDate: exitDate,
              exitPriceController: exitPriceController,
              exitQuantityController: exitQuantityController,
              onEntryDateChanged: onEntryDateSelected,
              onExitDateChanged: onExitDateSelected,
              showExit: selectedStatus != TradeStatuses.open,
            ),
          ],

          // Derivatives (if any)
          if (_isDerivativeSegment) ...[
            const SizedBox(height: 12),
            DerivativeCard(
              selectedDerivativeType: selectedDerivativeType,
              selectedOptionType: selectedOptionType,
              strikePriceController: strikePriceController,
              expiryDate: expiryDate,
              onDerivativeTypeChanged: onDerivativeTypeChanged,
              onOptionTypeChanged: onOptionTypeChanged,
              onExpiryDateTap: () => _selectExpiryDate(context),
            ),
          ],

          // Attachments
          const SizedBox(height: 16),
          TradeAttachmentSection(
            imageUrls: attachments,
            onAttachmentsChanged: onAttachmentsChanged,
            userId: userId ?? '',
            isEditMode: true,
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) onExpiryDateSelected(date);
  }
}
