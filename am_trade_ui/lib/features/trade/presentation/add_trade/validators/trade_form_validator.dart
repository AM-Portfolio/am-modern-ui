import '../../../internal/domain/enums/broker_types.dart';
import '../../../internal/domain/enums/exchange_types.dart';
import '../../../internal/domain/enums/market_segments.dart';
import '../../../internal/domain/enums/trade_statuses.dart';

/// Client-side trade form validation — mirrors server [TradeValidator] hard rules.
/// Returns a human-readable error, or null when valid.
class TradeFormValidator {
  const TradeFormValidator._();

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? positiveNumber(String? raw, {String label = 'Value'}) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final n = double.tryParse(text);
    if (n == null) return '$label must be a number';
    if (n <= 0) return '$label must be greater than 0';
    return null;
  }

  /// Step 0 / Save — required instrument + entry (+ exit when closed).
  static String? validateTradeDetails({
    required String symbol,
    required ExchangeTypes? selectedExchange,
    required MarketSegments? selectedSegment,
    required DateTime? entryDate,
    required String entryPrice,
    required String entryQuantity,
    required BrokerTypes? selectedBroker,
    required TradeStatuses status,
    required DateTime? exitDate,
    required String exitPrice,
    required String exitQuantity,
  }) {
    final symbolError = requiredText(symbol, label: 'Symbol');
    if (symbolError != null) return symbolError;
    if (selectedExchange == null) return 'Exchange is required';
    if (selectedSegment == null) return 'Segment is required';
    if (selectedBroker == null) return 'Broker is required';
    if (entryDate == null) return 'Entry date is required';

    final entryPriceError = positiveNumber(entryPrice, label: 'Entry price');
    if (entryPriceError != null) return entryPriceError;
    final entryQtyError = positiveNumber(entryQuantity, label: 'Entry quantity');
    if (entryQtyError != null) return entryQtyError;

    if (status == TradeStatuses.open) return null;

    if (exitDate == null) return 'Exit date is required for closed trades';
    final exitPriceError = positiveNumber(exitPrice, label: 'Exit price');
    if (exitPriceError != null) return exitPriceError;
    final exitQtyError = positiveNumber(exitQuantity, label: 'Exit quantity');
    if (exitQtyError != null) return exitQtyError;

    if (exitDate.isBefore(entryDate)) {
      return 'Exit date must be on or after entry date';
    }

    final entryQty = double.tryParse(entryQuantity.trim());
    final exitQty = double.tryParse(exitQuantity.trim());
    if (entryQty != null && exitQty != null && exitQty > entryQty) {
      return 'Exit quantity cannot exceed entry quantity';
    }

    return null;
  }

  /// @Deprecated — prefer [validateTradeDetails]
  static void validateRequiredFields({
    required String symbol,
    required selectedExchange,
    required selectedSegment,
    required DateTime? entryDate,
    required String entryPrice,
    required String entryQuantity,
    required selectedBroker,
  }) {
    final error = validateTradeDetails(
      symbol: symbol,
      selectedExchange: selectedExchange as ExchangeTypes?,
      selectedSegment: selectedSegment as MarketSegments?,
      entryDate: entryDate,
      entryPrice: entryPrice,
      entryQuantity: entryQuantity,
      selectedBroker: selectedBroker as BrokerTypes?,
      status: TradeStatuses.open,
      exitDate: null,
      exitPrice: '',
      exitQuantity: '',
    );
    if (error != null) throw ArgumentError(error);
  }

  /// @Deprecated — prefer [validateTradeDetails]
  static void validateNumericValues({
    required double? entryPrice,
    required double? entryQuantity,
  }) {
    if (entryPrice == null || entryPrice <= 0) {
      throw ArgumentError('Invalid entry price');
    }
    if (entryQuantity == null || entryQuantity <= 0) {
      throw ArgumentError('Invalid entry quantity');
    }
  }

  /// @Deprecated — prefer [validateTradeDetails]
  static void validateClosedTrade({
    required TradeStatuses status,
    required DateTime? exitDate,
    required double? exitPrice,
    required double? exitQuantity,
  }) {
    if (status == TradeStatuses.open) return;
    if (exitDate == null) {
      throw ArgumentError('Exit date is required for closed trades');
    }
    if (exitPrice == null || exitPrice <= 0) {
      throw ArgumentError('Invalid exit price for closed trades');
    }
    if (exitQuantity == null || exitQuantity <= 0) {
      throw ArgumentError('Invalid exit quantity for closed trades');
    }
  }
}
