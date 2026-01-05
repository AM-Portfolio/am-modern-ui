import '../../../internal/domain/enums/trade_statuses.dart';

/// Validator for trade form fields
class TradeFormValidator {
  const TradeFormValidator._();

  /// Validates required fields for trade creation
  static void validateRequiredFields({
    required String symbol,
    required selectedExchange,
    required selectedSegment,
    required DateTime? entryDate,
    required String entryPrice,
    required String entryQuantity,
    required selectedBroker,
  }) {
    if (symbol.isEmpty) {
      throw ArgumentError('Symbol is required');
    }
    if (selectedExchange == null) {
      throw ArgumentError('Exchange is required');
    }
    if (selectedSegment == null) {
      throw ArgumentError('Segment is required');
    }
    if (entryDate == null) {
      throw ArgumentError('Entry date is required');
    }
    if (entryPrice.isEmpty) {
      throw ArgumentError('Entry price is required');
    }
    if (entryQuantity.isEmpty) {
      throw ArgumentError('Entry quantity is required');
    }
    if (selectedBroker == null) {
      throw ArgumentError('Broker is required');
    }
  }

  /// Validates numeric values
  static void validateNumericValues({required double? entryPrice, required double? entryQuantity}) {
    if (entryPrice == null || entryPrice <= 0) {
      throw ArgumentError('Invalid entry price');
    }
    if (entryQuantity == null || entryQuantity <= 0) {
      throw ArgumentError('Invalid entry quantity');
    }
  }

  /// Validates exit data for closed trades
  static void validateClosedTrade({
    required TradeStatuses status,
    required DateTime? exitDate,
    required double? exitPrice,
    required double? exitQuantity,
  }) {
    if (status != TradeStatuses.open) {
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
}
