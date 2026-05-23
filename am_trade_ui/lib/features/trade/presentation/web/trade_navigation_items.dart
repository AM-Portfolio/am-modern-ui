
  void _initializeSwipeController() {
    _swipeController = SwipeNavigationController(
      items: [
        NavigationItem(
          title: 'Portfolios',
          subtitle: 'Select portfolio',
          icon: Icons.folder_outlined,
          page: TradePortfolioDiscoveryTemplate(
            onPortfolioSelected: (portfolio) {
              _onPortfolioSelected(portfolio.portfolioId, portfolio.portfolioName);
            },
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Holdings',
          subtitle: 'Current positions',
          icon: Icons.pie_chart_outlined,
          page: TradeHoldingsDashboardWebPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Trades',
          subtitle: 'Trade history',
          icon: Icons.list_alt_rounded,
          page: TradeListWebPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Calendar',
          subtitle: 'Trade calendar',
          icon: Icons.calendar_month_outlined,
          page: TradeCalendarAnalyticsWebPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Metrics',
          subtitle: 'Performance metrics',
          icon: Icons.analytics_outlined,
          page: TradeMetricsPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Journal',
          subtitle: 'Trade journal',
          icon: Icons.book_outlined,
          page: JournalWebPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Report',
          subtitle: 'Generate reports',
          icon: Icons.assessment_outlined,
          page: TradeReportPage(
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
      ],
    );
  }
