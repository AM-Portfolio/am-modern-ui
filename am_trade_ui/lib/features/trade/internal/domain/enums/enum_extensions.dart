import 'package:flutter/material.dart';
import 'broker_types.dart';
import 'derivative_types.dart';
import 'exchange_types.dart';
import 'market_segments.dart';
import 'option_types.dart';
import 'order_types.dart';

/// Extension for converting enums to dropdown items
extension BrokerTypesExt on BrokerTypes {
  DropdownMenuItem<BrokerTypes> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}

extension DerivativeTypesExt on DerivativeTypes {
  DropdownMenuItem<DerivativeTypes> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}

extension ExchangeTypesExt on ExchangeTypes {
  DropdownMenuItem<ExchangeTypes> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}

extension MarketSegmentsExt on MarketSegments {
  DropdownMenuItem<MarketSegments> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}

extension OptionTypesExt on OptionTypes {
  DropdownMenuItem<OptionTypes> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}

extension OrderTypesExt on OrderTypes {
  DropdownMenuItem<OrderTypes> toSimpleDropdownItem({required String text}) {
    return DropdownMenuItem(value: this, child: Text(text));
  }
}
