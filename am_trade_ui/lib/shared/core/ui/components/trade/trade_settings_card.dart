import 'package:flutter/material.dart';

import '../../../../../features/trade/internal/domain/enums/broker_types.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import '../../../../../features/trade/internal/domain/enums/order_types.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import 'package:am_design_system/am_design_system.dart';

/// Trade settings card (Broker & Order Type)
class TradeSettingsCard extends StatelessWidget {
  const TradeSettingsCard({
    required this.selectedBroker,
    required this.selectedOrderType,
    required this.onBrokerChanged,
    required this.onOrderTypeChanged,
    super.key,
  });

  final BrokerTypes? selectedBroker;
  final OrderTypes? selectedOrderType;
  final ValueChanged<BrokerTypes?> onBrokerChanged;
  final ValueChanged<OrderTypes?> onOrderTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.tune, size: 16, color: Colors.purple),
            ),
            const SizedBox(width: 8),
            Text(
              'Trade Settings',
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: CustomDropdown<BrokerTypes>(
              value: selectedBroker,
              hint: isMobile ? 'Broker' : 'Select Broker',
              items: BrokerTypes.values
                  .map((broker) => broker.toSimpleDropdownItem(text: broker.toString().split('.').last.toUpperCase()))
                  .toList(),
              onChanged: onBrokerChanged,
              icon: isMobile ? null : Icons.business_center,
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: CustomDropdown<OrderTypes>(
              value: selectedOrderType,
              hint: isMobile ? 'Order' : 'Select Order Type',
              items: OrderTypes.values
                  .map((type) => type.toSimpleDropdownItem(text: type.toString().split('.').last.toUpperCase()))
                  .toList(),
              onChanged: onOrderTypeChanged,
              icon: isMobile ? null : Icons.receipt_long,
            ),
          ),
        ],
      ),
    );
  }
}
