import '../entities/trade_calendar.dart';
import '../entities/trade_holding.dart';
import '../entities/trade_portfolio.dart';
import '../entities/trade_summary.dart';

/// Repository interface for trade data operations
abstract class TradeRepository {
  /// Get list of portfolios for trading
  Future<TradePortfolioList> getTradePortfolios(String userId);

  /// Get holdings for a specific trade portfolio
  Future<TradeHoldings> getTradeHoldings(String userId, String portfolioId);

  /// Get summary/analysis for a specific trade portfolio
  Future<TradeSummary> getTradeSummary(String userId, String portfolioId);

  /// Get calendar analytics by month for a specific trade portfolio
  Future<TradeCalendar> getTradeCalendarByMonth(
    String userId,
    String portfolioId, {
    required int year,
    required int month,
  });

  /// Get calendar analytics by day for a specific trade portfolio
  Future<TradeCalendar> getTradeCalendarByDay(String userId, String portfolioId, {required DateTime date});

  /// Get calendar analytics by date range for a specific trade portfolio
  Future<TradeCalendar> getTradeCalendarByDateRange(
    String userId,
    String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get calendar analytics by quarter for a specific trade portfolio
  Future<TradeCalendar> getTradeCalendarByQuarter(
    String userId,
    String portfolioId, {
    required int year,
    required int quarter,
  });

  /// Get calendar analytics by financial year for a specific trade portfolio
  Future<TradeCalendar> getTradeCalendarByFinancialYear(
    String userId,
    String portfolioId, {
    required int financialYear,
  });

  /// Get calendar analytics for a specific trade portfolio (legacy - delegates to getTradeCalendarByMonth)
  @Deprecated('Use getTradeCalendarByMonth instead')
  Future<TradeCalendar> getTradeCalendar(String userId, String portfolioId, {int? year, int? month});

  /// Get portfolios stream for real-time updates
  Stream<TradePortfolioList> watchTradePortfolios(String userId);

  /// Get holdings stream for real-time updates
  Stream<TradeHoldings> watchTradeHoldings(String userId, String portfolioId);

  /// Get summary stream for real-time updates
  Stream<TradeSummary> watchTradeSummary(String userId, String portfolioId);

  /// Get calendar stream for real-time updates
  Stream<TradeCalendar> watchTradeCalendar(String userId, String portfolioId);
}
