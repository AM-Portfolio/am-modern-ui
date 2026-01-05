import 'package:json_annotation/json_annotation.dart';

import 'trade_controller_dtos.dart';

part 'trade_calendar_dto.g.dart';

/// DTO for trade calendar response from API
/// API returns: { "portfolioId": [TradeDetailsDto, ...] }
@JsonSerializable()
class TradeCalendarDto {
  const TradeCalendarDto({required this.portfolioTrades});

  factory TradeCalendarDto.fromJson(Map<String, dynamic> json) {
    final portfolioTrades = <String, List<TradeDetailsDto>>{};

    for (final entry in json.entries) {
      final portfolioId = entry.key;
      final tradesJson = entry.value as List<dynamic>;

      portfolioTrades[portfolioId] = tradesJson
          .map((tradeJson) => TradeDetailsDto.fromJson(tradeJson as Map<String, dynamic>))
          .toList();
    }

    return TradeCalendarDto(portfolioTrades: portfolioTrades);
  }

  final Map<String, List<TradeDetailsDto>> portfolioTrades;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    for (final entry in portfolioTrades.entries) {
      json[entry.key] = entry.value.map((trade) => trade.toJson()).toList();
    }

    return json;
  }
}

/// DTO for trade calendar by month response
/// Uses the same structure as TradeCalendarDto
typedef TradeCalendarMonthDto = TradeCalendarDto;

/// DTO for trade calendar by day response
/// API returns: { "portfolioId": [TradeDetailsDto, ...] }
typedef TradeCalendarDayDto = TradeCalendarDto;

/// DTO for trade calendar by date range response
/// API returns: { "portfolioId": [TradeDetailsDto, ...] }
typedef TradeCalendarDateRangeDto = TradeCalendarDto;

/// DTO for trade calendar by quarter response
/// API returns: { "portfolioId": [TradeDetailsDto, ...] }
typedef TradeCalendarQuarterDto = TradeCalendarDto;

/// DTO for trade calendar by financial year response
/// API returns: { "portfolioId": [TradeDetailsDto, ...] }
typedef TradeCalendarFinancialYearDto = TradeCalendarDto;
