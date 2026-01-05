import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:am_common/core/utils/logger.dart';
import '../dtos/trade_calendar_dto.dart';
import '../dtos/trade_holding_dto.dart';
import '../dtos/trade_portfolio_dto.dart';
import '../dtos/trade_portfolio_summary_dto.dart';

/// Helper class to load mock trade data from JSON files
class TradeMockDataHelper {
  /// Get mock trade portfolios from JSON file
  static Future<TradePortfolioListDto> getMockTradePortfolios() async {
    try {
      AppLogger.info('Loading mock trade portfolios from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString('assets/mock_data/trade/trade_portfolios.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradePortfolioListDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade portfolios', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }

  /// Get mock trade holdings from JSON file
  static Future<TradeHoldingsDto> getMockTradeHoldings() async {
    try {
      AppLogger.info('Loading mock trade holdings from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString('assets/mock_data/trade/holdings/trade_holdings.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradeHoldingsDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade holdings', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }

  /// Get mock trade portfolio summary from JSON file
  static Future<TradePortfolioSummaryDto> getMockTradeSummary() async {
    try {
      AppLogger.info('Loading mock trade portfolio summary from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString('assets/mock_data/trade/trade_summary.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradePortfolioSummaryDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade portfolio summary', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }

  /// Get mock trade calendar from JSON file
  static Future<TradeCalendarDto> getMockTradeCalendar() async {
    try {
      AppLogger.info('Loading mock trade calendar from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString('assets/mock_data/trade/calander/trade_calendar.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradeCalendarDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade calendar', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }

  /// Get mock trade calendar by day from JSON file
  static Future<TradeCalendarDto> getMockTradeCalendarByDay() async {
    try {
      AppLogger.info('Loading mock trade calendar by day from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString(
        'assets/mock_data/trade/calander/calender-by-day-response.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradeCalendarDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade calendar by day', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }

  /// Get mock trade calendar by date range from JSON file
  static Future<TradeCalendarDto> getMockTradeCalendarByDateRange() async {
    try {
      AppLogger.info('Loading mock trade calendar by date range from assets', tag: 'TradeMockDataHelper');

      final jsonString = await rootBundle.loadString(
        'assets/mock_data/trade/calander/calender-by-date-range-response.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TradeCalendarDto.fromJson(jsonData);
    } catch (e) {
      AppLogger.error('Failed to load mock trade calendar by date range', tag: 'TradeMockDataHelper', error: e);
      rethrow;
    }
  }
}
