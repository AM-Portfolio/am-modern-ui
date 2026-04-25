# am_dashboard_ui

## Purpose
- High-level summary of user's investment ecosystem
- Aggregates data from portfolios, shows top movers and performance charts
- Hybrid module: Uses both REST APIs and real-time STOMP WebSockets

## Architecture
- **Presentation**: `am_design_system`, `fl_chart`, `DashboardPage`, `PortfolioOverviewCard`
- **State Management**: `@riverpod` (Code-generated Riverpod providers)
- **Domain**: Entities (`DashboardSummary`, `PortfolioOverview`, `TopMoversResponse`, etc.)
- **Data**: `DashboardRepository` connects to Analysis Microservice and STOMP server

## Data Flow (Hybrid Approach)

### Static / On-Demand Data
- Pure REST HTTP GET calls returning `Future`s
- Endpoints hit the **Analysis Microservice** (`/api/v1/analysis/dashboard/...`)
  - `portfolioOverviews()`
  - `topMovers()`
  - `dashboardPerformance()`
  - `recentActivity()`

### Real-Time Data Stream (The Hybrid Pattern)
- Managed by `dashboardStreamProvider` (`async*` generator)
- **Step 1: REST Initial Load**
  - Instantly calls `repository.getSummary(userId)` via HTTP GET
  - Yields initial data to prevent empty/loading screens
- **Step 2: WebSocket Subscription**
  - Yields the stream from `repository.getDashboardStream(userId)`
  - Relies on `AmStompClient` from `am_library`
  - Subscribes to STOMP topic: `/topic/dashboard/$userId`
  - Parses incoming JSON messages into `DashboardSummary` objects

## Key Differences vs Trade UI
- **Real WebSockets**: Uses actual STOMP WebSockets, whereas Trade UI uses fake streams (REST polling + Dart StreamControllers)
- **Code Gen**: Uses `riverpod_generator` (`@riverpod`) instead of manual provider declarations
- **API Target**: Hits the Analysis API, not the Trade API

## Critical Gotchas
- **Analysis API Config**: Depends on `analysisApiClientProvider`. If `ConfigService` has `localhost`, dashboard fails.
- **WebSocket Lifecycle**: Assumes `AmStompClient` is already connected globally (usually handled in Portfolio wrapper). If disconnected, the stream stalls.
- **Empty Body Exception**: If the backend sends an empty STOMP frame to the dashboard topic, the parser throws a synchronous exception, potentially breaking the stream.


test