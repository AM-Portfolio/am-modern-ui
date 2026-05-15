import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';
import '../dtos/portfolio_holdings_dto.dart';
import '../dtos/portfolio_summary_dto.dart';
import '../dtos/portfolio_list_dto.dart';

/// Mapper class for Portfolio API operations
///
/// Handles conversion between API requests/responses and data transfer objects,
/// following the same pattern as AuthMapper for consistency
class PortfolioMapper {
  /// Create API request body for fetching portfolio holdings
  static Map<String, dynamic> portfolioHoldingsRequestToJson(String userId) => {
    'userId': userId,
  };

  /// Create API request body for fetching portfolio summary
  static Map<String, dynamic> portfolioSummaryRequestToJson(String userId) => {
    'userId': userId,
  };

  /// Parse portfolio holdings from API response JSON
  static PortfolioHoldingsDto portfolioHoldingsFromJson(
    Map<String, dynamic> json,
  ) {
    try {
      return PortfolioHoldingsDto.fromJson(json);
    } catch (e) {
      CommonLogger.error(
        'Failed to parse portfolio holdings response',
        tag: 'PortfolioMapper',
        error: e,
      );
      throw Exception('Invalid portfolio holdings response format');
    }
  }

  /// Parse portfolio summary from API response JSON
  static PortfolioSummaryDto portfolioSummaryFromJson(
    Map<String, dynamic> json,
  ) {
    try {
      return PortfolioSummaryDto.fromJson(json);
    } catch (e) {
      CommonLogger.error(
        'Failed to parse portfolio summary response',
        tag: 'PortfolioMapper',
        error: e,
      );
      throw Exception('Invalid portfolio summary response format');
    }
  }

  /// Parse portfolio list from API response.
  ///
  /// The backend returns `List<PortfolioBasicInfo>` as a raw JSON array.
  /// This method handles:
  /// - `List<dynamic>`: Direct array from backend
  /// - `Map<String, dynamic>`: Wrapper with "value" key (defensive)
  static PortfolioListDto portfolioListFromJson(dynamic json) {
    try {
      if (json is List) {
        return PortfolioListDto.fromJson(json);
      }
      // Defensive: if response is wrapped in a map (e.g. {"value": [...]})
      if (json is Map<String, dynamic>) {
        if (json.containsKey('value') && json['value'] is List) {
          return PortfolioListDto.fromJson(json['value'] as List<dynamic>);
        }
        // Single item wrapped in a map
        CommonLogger.warning(
          'Portfolio list returned as Map instead of List. Keys: ${json.keys}',
          tag: 'PortfolioMapper',
        );
        return PortfolioListDto(portfolios: []);
      }
      CommonLogger.warning(
        'Unexpected portfolio list response type: ${json.runtimeType}',
        tag: 'PortfolioMapper',
      );
      return PortfolioListDto(portfolios: []);
    } catch (e) {
      CommonLogger.error(
        'Failed to parse portfolio list response',
        tag: 'PortfolioMapper',
        error: e,
      );
      throw Exception('Invalid portfolio list response format');
    }
  }

  // Note: Error parsing is now handled by ApiClient's built-in exception system
}
