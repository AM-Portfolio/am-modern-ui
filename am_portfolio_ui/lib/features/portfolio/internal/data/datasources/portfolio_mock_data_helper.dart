import 'package:am_design_system/am_design_system.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../dtos/portfolio_summary_dto.dart';
import '../dtos/portfolio_holdings_dto.dart';
import '../dtos/portfolio_analytics_response_dto.dart';
import '../mappers/portfolio_mapper.dart';
import '../mappers/portfolio_analytics_mapper.dart';
import 'package:am_common/core/utils/logger.dart';

/// Helper class to load mock data from JSON assets
class PortfolioMockDataHelper {
  static Map<String, dynamic>? _cachedSummary;
  static Map<String, dynamic>? _cachedHoldings;
  static Map<String, dynamic>? _cachedAnalytics;

  /// Load mock portfolio summary
  static Future<PortfolioSummaryDto> getMockPortfolioSummary() async {
    try {
      if (_cachedSummary == null) {
        final jsonString = await rootBundle
            .loadString('assets/mock_data/portfolio_summary.json');
        _cachedSummary = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Use mapper to convert JSON to DTO
      return PortfolioMapper.portfolioSummaryFromJson(_cachedSummary!);
    } catch (e) {
      CommonLogger.error(
        'Failed to load mock portfolio summary',
        tag: 'PortfolioMockDataHelper',
        error: e,
      );
      rethrow;
    }
  }

  /// Load mock portfolio holdings
  static Future<PortfolioHoldingsDto> getMockPortfolioHoldings() async {
    try {
      if (_cachedHoldings == null) {
        final jsonString = await rootBundle
            .loadString('assets/mock_data/portfolio_holdings.json');
        _cachedHoldings = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Use mapper to convert JSON to DTO
      return PortfolioMapper.portfolioHoldingsFromJson(_cachedHoldings!);
    } catch (e) {
      CommonLogger.error(
        'Failed to load mock portfolio holdings',
        tag: 'PortfolioMockDataHelper',
        error: e,
      );
      rethrow;
    }
  }

  /// Load mock portfolio analytics
  static Future<PortfolioAnalyticsResponseDto> getMockPortfolioAnalytics() async {
    try {
      if (_cachedAnalytics == null) {
        final jsonString = await rootBundle
            .loadString('assets/mock_data/portfolio_analytics.json');
        _cachedAnalytics = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Use mapper to convert JSON to DTO
      return PortfolioAnalyticsMapper.responseFromJson(_cachedAnalytics!);
    } catch (e) {
      CommonLogger.error(
        'Failed to load mock portfolio analytics',
        tag: 'PortfolioMockDataHelper',
        error: e,
      );
      rethrow;
    }
  }

  /// Clear cached data
  static void clearCache() {
    _cachedSummary = null;
    _cachedHoldings = null;
    _cachedAnalytics = null;
  }
}
