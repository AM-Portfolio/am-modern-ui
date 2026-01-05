
  void _initializeSwipeController() {
    _swipeController = SwipeNavigationController(
      items: [
        NavigationItem(
          title: 'Portfolios',
          subtitle: 'Select portfolio',
          icon: Icons.folder_outlined,
          page: TradePortfolioDiscoveryTemplate(
            userId: widget.userId,
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
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Trades',
          subtitle: 'Trade history',
          icon: Icons.list_alt_rounded,
          page: TradeListWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Calendar',
          subtitle: 'Trade calendar',
          icon: Icons.calendar_month_outlined,
          page: TradeCalendarAnalyticsWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Metrics',
          subtitle: 'Performance metrics',
          icon: Icons.analytics_outlined,
          page: TradeMetricsPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Journal',
          subtitle: 'Trade journal',
          icon: Icons.book_outlined,
          page: JournalWebPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
        NavigationItem(
          title: 'Report',
          subtitle: 'Generate reports',
          icon: Icons.assessment_outlined,
          page: TradeReportPage(
            userId: widget.userId,
            portfolioId: _currentPortfolioId,
          ),
          accentColor: ModuleColors.trade,
        ),
      ],
    );
  }
