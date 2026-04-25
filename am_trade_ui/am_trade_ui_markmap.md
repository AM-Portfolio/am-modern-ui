# am_trade_ui

## Purpose
- Flutter package for the Trade Management module
- Handles: Trade entry, Holdings, Calendar, Journal, Metrics, Reports, Notebook
- Runs standalone on port 8083 or embedded inside am_app
- Backend: https://am.munish.org/trades

## Sibling Dependencies (local packages)
- am_design_system — all UI components, theme, navigation
- am_common — ApiClient, AppLogger, ConfigService, AppConfig
- am_library — base utilities, ApiClient class
- am_auth_ui — auth wrappers, JWT token management
- am_portfolio_ui — portfolio view models
- am_market_ui — TradingView chart widget (Market tab)

## External Packages
- flutter_riverpod + riverpod_annotation — DI + async providers
- flutter_bloc — Cubit state management
- freezed + freezed_annotation — immutable domain models
- json_annotation + json_serializable — JSON parsing
- dio — HTTP client (via am_common's ApiClient)
- fl_chart — analytics charts
- flutter_quill — rich text editor (Journal)
- image_picker — file attachment picker
- get_it + injectable — service locator (DI)
- dartz — functional programming (Either/Option)
- intl — date and number formatting

## Configuration
- API Base URL (TradeEndpoints): https://am.munish.org/trades
- API Base URL (ConfigService): https://am.munish.org/api/trade
- Application Properties: assets/application.properties
- useMockData: true (hardcoded in ConfigService — change to false for real API)
- Dev port: 8083 (npm run run:trade)

## Entry Points
- lib/main.dart — standalone runner → TradeWebScreen()
- lib/am_trade_ui.dart — exports TradeWebScreen + AddTradeWebPage
- TradeWebScreen(userId: String) — the root widget

## The 9 Tabs / Screens

### Tab 0: Portfolios
- Widget: TradePortfolioDiscoveryTemplate
- Data: tradePortfoliosStreamProvider(userId)
- API: GET /api/v1/portfolio-summary/by-owner/{userId}

### Tab 1: Holdings (needs portfolio selected)
- Widget: TradeHoldingsDashboardWebPage → TradeHoldingsAdvancedTemplate
- Data: tradeHoldingsStreamProvider({userId, portfolioId})
- API: GET /api/v1/trades/details/portfolio/{portfolioId}
- Features: filter panel, detail drill-down, symbol tap → Market chart

### Tab 2: Calendar (needs portfolio selected)
- Widget: TradeCalendarAnalyticsWebPage
- Cubit: TradeCalendarCubit
- Hierarchical navigation: Yearly → Monthly → Daily
- API Yearly: GET /v1/trades/calendar/custom?startDate=&endDate=
- API Monthly: GET /v1/trades/calendar/month?portfolioId=&year=&month=
- API Daily: GET /v1/trades/calendar/day?date=&portfolioId=

### Tab 3: Trades (needs portfolio selected)
- Widget: TradeListWebPage
- Data: tradesByFiltersProvider / tradeDetailsByPortfolioProvider
- API: GET /v1/trades/filter (paginated)
- Features: filter by status/date/strategy, detail view page

### Tab 4: Journal
- Widget: JournalWebPage
- Cubit: JournalCubit
- CRUD operations for journal entries
- Uses flutter_quill for rich text editing

### Tab 5: Analysis (needs portfolio selected)
- Widget: TradeMetricsPage
- Cubit: TradeMetricsCubit
- API: GET /v1/metrics + GET /v1/metrics/types
- Shows: Net P&L, Win Rate, Sharpe Ratio, Max Drawdown
- Charts: Trades by Day bar chart, Asset Class pie chart, Strategy pie chart
- Default date range: 1919-01-01 to today (all time)

### Tab 6: Market
- Widget: TradeMarketPage
- Embeds am_market_ui components (TradingView chart)
- No trade API calls — uses market module's own providers

### Tab 7: Report (needs portfolio selected)
- Widget: TradeReportPage
- Cubit: TradeReportCubit
- Generates downloadable performance reports

### Tab 8: Unified
- Widget: TradeUnifiedViewPage
- Combined dashboard view

## Add Trade Flow
- Button: "Add Trade" (SidebarPrimaryAction)
- Route: /trade/add via Navigator.pushNamed
- Widget: AddTradeWebPage → AddTradeForm
- Steps
  - Step 1: InstrumentDetailsStep — Symbol, Exchange, Segment, Derivative
  - Step 2: TradeDetailsStep — Direction, Entry Date/Price/Qty, Exit Date/Price/Qty
  - Step 3: OptionalDetailsStep — Psychology, Reasoning, Tags, Notes, Attachments
  - Step 4: ReviewStep — Summary before submit
- Submits via: TradeControllerCubit.addNewTrade(TradeDetails)
- API: POST /v1/trades/details
- Status: 85% complete — entity construction in _saveTrade() is incomplete

## State Management

### Riverpod (for READ)
- tradePortfoliosStreamProvider(userId) → StreamProvider
- tradeHoldingsStreamProvider({userId, portfolioId}) → StreamProvider.family
- tradeCalendarByMonthProvider → FutureProvider.family
- tradeDetailsByPortfolioProvider → StreamProvider.family
- tradeMetricsCubitProvider → FutureProvider

### Bloc/Cubit (for WRITE + complex state)
- TradeControllerCubit — add/update/delete trades
  - States: initial, loading, loaded, adding, addSuccess, updating, updateSuccess, deleting, deleteSuccess, error
- TradeCalendarCubit — calendar navigation state
  - Has CalendarNavigationService + CalendarAggregationService
  - Retry with exponential backoff (3 attempts)
- TradeMetricsCubit — analytics state
- TradeReportCubit — report generation
- JournalCubit — journal entry CRUD
- FavoriteFilterCubit — saved filter management
- NotebookCubit — notebook items + tags

## Data Flow (Read)
- Widget watches StreamProvider via ref.watch
- Provider calls UseCase
- UseCase validates inputs → calls Repository
- Repository checks in-memory cache → calls RemoteDataSource
- RemoteDataSource calls ApiClient (Dio + JWT interceptor)
- HTTP response parsed into DTO (fromJson)
- Repository maps DTO → Domain Entity via Mapper
- Repository pushes entity to StreamController (broadcast)
- Widget auto-rebuilds

## Data Flow (Write)
- Widget calls Cubit method (e.g., addNewTrade)
- Cubit emits loading state
- Cubit calls UseCase
- UseCase validates → calls Repository
- Repository converts Entity → DTO via Mapper
- RemoteDataSource calls ApiClient POST/PUT/DELETE
- Repository refreshes portfolio cache
- Repository emits updated list to broadcast stream
- Cubit emits success state
- Cubit auto-calls loadTrades() to refresh list

## Clean Architecture Layers

### Data Layer (internal/data)
- datasources/
  - trade_remote_data_source.dart — portfolios, holdings, calendar, summary
  - trade_controller_remote_data_source.dart — CRUD, filter, batch
  - journal_remote_data_source.dart
  - favorite_filter_remote_data_source.dart
  - notebook_remote_datasource.dart
  - trade_metrics_remote_data_source.dart
  - trade_report_remote_data_source.dart
  - trade_mock_data_helper.dart — loads mock JSON from assets
- dtos/ — JSON models (toJson/fromJson via json_serializable)
  - TradeDetailsDto, InstrumentInfoDto, EntryExitInfoDto, TradeMetricsDto, etc.
- mappers/ — DTO ↔ Domain Entity conversion (15 mapper classes)
  - trade_controller_mapper.dart (largest — 387 lines, 15 entity types)
  - trade_calendar_mapper.dart
  - trade_holding_mapper.dart
  - trade_portfolio_mapper.dart, etc.
- repositories/ — 8 repository implementations
  - trade_repository_impl.dart — 5 StreamControllers, in-memory cache
  - trade_controller_repository_impl.dart — Map cache + broadcast stream

### Domain Layer (internal/domain)
- entities/ — pure Dart, Freezed, no JSON
  - TradeDetails (main entity — 15 fields)
  - InstrumentInfo, EntryExitInfo, TradeMetrics, TradePsychologyData
  - TradeEntryExitReasoning, DerivativeInfo, Attachment
  - TradeCalendar, TradeHoldings, TradePortfolio, TradeSummary
  - FavoriteFilter, MetricsFilterConfig, etc.
- enums/ — 15+ enums
  - TradeStatuses (open, closed, partialExit)
  - TradeDirections (long, short)
  - MarketSegments (equity, fno, commodity, currency)
  - ExchangeTypes (NSE, BSE, MCX, NFO)
  - DerivativeTypes (futures, options, etc.)
  - EntryPsychologyFactors, ExitPsychologyFactors
  - TechnicalReasons, FundamentalReasons, etc.
- repositories/ — abstract interfaces (contracts)
  - TradeRepository (read operations)
  - TradeControllerRepository (write operations)
  - JournalRepository, FavoriteFilterRepository, etc.
- usecases/ — 34 use cases (one class per business operation)
  - AddTrade, UpdateTrade, DeleteTrade, GetTradesByPortfolio
  - GetTradeHoldings, GetTradePortfolios, GetTradeSummary
  - GetTradeCalendar, GetTradeCalendarByMonth, GetTradeCalendarByDay, etc.
  - GetTradeMetrics, GetMetricTypes
  - CreateJournalEntry, UpdateJournalEntry, DeleteJournalEntry
  - CreateFavoriteFilter, DeleteFavoriteFilter, SetDefaultFilter, etc.

### Presentation Layer (presentation)
- web/ — TradeWebScreen (root), portfolio auto-selection
- add_trade/ — 4-step wizard form
- holdings/ — dashboard + advanced template + filter integration
- calendar/ — hierarchical calendar analytics
- trades/ — trade list + detail view
- journal/ — rich text journal page
- metrics/ — analytics dashboard
- report/ — report generation page
- notebook/ — notebook items + tags
- pages/ — TradeMarketPage, TradeUnifiedViewPage
- models/ — view models (ViewModel layer, DTO → what widget shows)
- cubit/ — all Cubits + States
- services/ — CalendarNavigationService, CalendarAggregationService
- converters/ — TradeCalendarConverter (entity → calendar card data)
- widgets/ — shared presentation widgets (FilterPanel, etc.)

## API Endpoints

### Portfolios & Holdings
- GET /api/v1/portfolio-summary/by-owner/{userId}
- GET /api/v1/portfolio-summary/{portfolioId}
- GET /api/v1/trades/details/portfolio/{portfolioId}

### Trade CRUD
- GET /v1/trades/details/portfolio/{portfolioId}?symbols=
- POST /v1/trades/details (Add trade)
- PUT /v1/trades/details/{tradeId} (Update trade)
- DELETE /v1/trades/details/{tradeId}
- POST /v1/trades/details/batch (bulk add/update)
- POST /v1/trades/details/by-ids (fetch by IDs)

### Filtering
- GET /v1/trades/filter?portfolioIds=&symbols=&statuses=&startDate=&endDate=&strategies=
- POST /v1/trades/details/filter (filter by FavoriteFilter config)

### Calendar
- GET /v1/trades/calendar/month?portfolioId=&year=&month=
- GET /v1/trades/calendar/day?date=&portfolioId=
- GET /v1/trades/calendar/quarter?portfolioId=&year=&quarter=
- GET /v1/trades/calendar/financial-year?portfolioId=&financialYear=
- GET /v1/trades/calendar/custom?portfolioId=&startDate=&endDate=

### Metrics & Reports
- GET /v1/metrics (with MetricsFilterRequest body)
- GET /v1/metrics/types

## Mock Data (Assets)
- assets/mock_data/trade/trade_portfolios.json
- assets/mock_data/trade/trade_summary.json
- assets/mock_data/trade/holdings/trade_holdings.json
- assets/mock_data/trade/calander/trade_calendar.json (typo: "calander")
- assets/mock_data/trade/calander/calender-by-day-response.json
- assets/mock_data/trade/calander/calender-by-date-range-response.json

## Critical Gotchas
- useMockData: true — change to false to hit real backend
- Two conflicting base URLs: /trades vs /api/trade
- DTO typo: streategy (not strategy) — do NOT fix without backend sync
- portfolioId must be passed explicitly to AddTradeForm or it throws
- "calander" folder typo — do NOT rename
- Run `npm run gen:trade` after any Freezed/JSON model change
- StreamControllers are never re-created — ref.invalidate() forces a fresh API call
- Tabs 1,2,3,5,7 show PortfolioSelectionPrompt if no portfolio is selected

## Dev Commands (from root)
- `npm run get:trade` — flutter pub get
- `npm run gen:trade` — dart run build_runner build
- `npm run run:trade` — flutter run -d chrome --web-port 8083
- `npm run build:trade` — flutter build web
- `npm run test:trade` — flutter test
- `npm run clean:trade` — flutter clean
