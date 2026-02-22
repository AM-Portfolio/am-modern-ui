# Dashboard & Analysis Enhancement Implementation Plan

## Goal Description
Create a comprehensive Dashboard in a **NEW** `am_dashboard_ui` Flutter module with real-time streaming updates, following a strict **Phased & Self-Verifying** approach.

## User Review Required
> [!IMPORTANT]
> **Phased Execution**: Implementation will proceed in 4 strict phases.
> **Self-Verification**: Each phase ENDS with a mandatory Build/Test cycle. Work will NOT proceed to the next phase until the current module is error-free.
> **Autonomous**: The agent will fix any build errors encountered during verification without asking the user.

## Phase 1: Trade Infrastructure (Backend) [DONE]
**Goal**: Establish the domain models and client library for accessing Trade data.
1.  **Module**: `am-core-services/domain/am-trade-domain`
    - Define POJOs: `TradePortfolio`, `TradeHolding`, `TradeTransaction`, `PortfolioOverview`.
2.  **Module**: `am-core-services/libraries/am-trade-client-lib`
    - Wrapper for `am-trade-sdk`.
    - Implement `TradeClientService`.
3.  **Verification (Autonomous)**:
    - Run `mvn clean install -pl domain/am-trade-domain,libraries/am-trade-client-lib`
    - Fix any compilation/dependency errors.

## Phase 2: Analysis Logic & Aggregation (Backend) [DONE]
**Goal**: Implement the business logic for aggregating AM + Trade portfolios and exposing granular endpoints.
1.  **Component**: `AnalysisAggregator` in `am-analysis`.
    - Central logic to combine `AMPortfolio` and `TradePortfolio`.
2.  **Service**: `DashboardAnalysisService`.
    - Implement REST Getters (`summary`, `chart`, etc.).
    - Implement Kafka Publisher for `DASHBOARD_UPDATE`.
3.  **Controller**: `AnalysisController`.
    - Add endpoints: `/dashboard/summary`, `/dashboard/chart`, etc.
4.  **Verification (Autonomous)**:
    - Run `mvn clean install -pl services/am-analysis`
    - Run Unit Tests for `AnalysisAggregator`.

## Phase 3: Gateway Streaming (Backend) [DONE]
**Goal**: Enable real-time push of dashboard updates to the frontend.
1.  **Library**: `am-kafka-lib`.
    - Add `DASHBOARD_UPDATE` topic constant.
2.  **Service**: `am-gateway`.
    - Update `KafkaRelayService` to listen to `DASHBOARD_UPDATE`.
    - Implement WebSocket push to `/topic/dashboard/{userId}`.
3.  **Verification (Autonomous)**:
    - Run `mvn clean install -pl services/am-gateway`
    - Ensure no WebSocket config conflicts.

## Phase 4: Dashboard UI (Frontend) [IN PROGRESS]
**Goal**: Create the visual dashboard consuming both REST and WebSocket data.

### 4.1: Foundation & Summary [DONE]
1.  **Module**: `am-modern-ui/am_dashboard_ui`.
    - Create module structure.
    - specific `pubspec.yaml`.
2.  **Logic**: `DashboardRepository` & `DashboardProvider`.
    - `DashboardSummary` model & provider.
    - `PortfolioOverview` model & provider.
3.  **UI**:
    - `DashboardSummaryWidget` (Cards).
    - `DashboardAllocationWidget` (Donut Chart).
    - `PortfolioOverviewCard` (List).

### 4.2: Ranking & Top Movers [NEXT]
1.  **Backend**: Confirm `AnalysisController` has `/dashboard/top-movers`.
2.  **Frontend Logic**:
    - `TopMoversResponse` model (Freezed).
    - `topMoversProvider` (Riverpod).
3.  **UI**:
    - `DashboardRankingWidget` (Tabs: Gainers/Losers).
    - Use `AmDesignSystem` tables or list tiles.

### 4.3: Historical Performance Chart
1.  **Backend**: Confirm `AnalysisController` has `/dashboard/performance`.
2.  **Frontend Logic**:
    - `PerformanceResponse` model (Freezed).
    - `performanceProvider` (Riverpod).
3.  **UI**:
    - `DashboardChartWidget` (Line Chart).
    - Use `fl_chart` via `AmDesignSystem`.
    - Timeframe selector (1D, 1W, 1M, 1Y).

### 4.4: Recent Activity
1.  **Backend**: Provide `/dashboard/recent-activity`.
2.  **Frontend Logic**:
    - `ActivityItem` model.
    - `recentActivityProvider`.
3.  **UI**:
    - `RecentActivityWidget` (List).

## Final Verification
- **E2E Check**: Ensure all services build together (`mvn clean install`) and Frontend compiles.
