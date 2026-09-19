import 'news_ui_surface.dart';

/// GrowthBook key strings for modern-ui News (do not put these in [FeatureFlagKeys]).
class NewsFeatureFlagKeys {
  NewsFeatureFlagKeys._();

  static const enabled = 'news-ui-enabled';
  static const dashboard = 'news-ui-dashboard';
  static const equityInsider = 'news-ui-equity-insider';
  static const watchList = 'news-ui-watch-list';
  static const marketAnalysis = 'news-ui-market-analysis';
  static const paper = 'news-ui-paper';
  static const portfolioOverview = 'news-ui-portfolio-overview';
  static const portfolioHoldings = 'news-ui-portfolio-holdings';
  static const portfolioBaskets = 'news-ui-portfolio-baskets';
  static const tradeHoldings = 'news-ui-trade-holdings';
  static const tradeTrades = 'news-ui-trade-trades';
  static const tradeUnified = 'news-ui-trade-unified';
  static const tradeJournal = 'news-ui-trade-journal';

  static String keyFor(NewsUiSurface surface) => switch (surface) {
        NewsUiSurface.dashboard => dashboard,
        NewsUiSurface.equityInsider => equityInsider,
        NewsUiSurface.watchList => watchList,
        NewsUiSurface.marketAnalysis => marketAnalysis,
        NewsUiSurface.paper => paper,
        NewsUiSurface.portfolioOverview => portfolioOverview,
        NewsUiSurface.portfolioHoldings => portfolioHoldings,
        NewsUiSurface.portfolioBaskets => portfolioBaskets,
        NewsUiSurface.tradeHoldings => tradeHoldings,
        NewsUiSurface.tradeTrades => tradeTrades,
        NewsUiSurface.tradeUnified => tradeUnified,
        NewsUiSurface.tradeJournal => tradeJournal,
      };
}
