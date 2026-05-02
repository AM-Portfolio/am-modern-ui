# am_library

## Purpose
- Core infrastructure package — no UI, no business logic
- Provides: HTTP client, WebSocket STOMP client, JWT storage, DI hub, logging, env config, telemetry
- Used by: am_portfolio_ui, am_dashboard_ui, am_market_ui
- NOT used directly by am_trade_ui (trade uses am_common's Dio-based client)

## Dependencies
- http (REST HTTP calls)
- dio (imported but main client uses http pkg)
- stomp_dart_client (WebSocket STOMP protocol)
- rxdart (reactive streams — PublishSubject, BehaviorSubject, ReplaySubject)
- flutter_secure_storage (encrypted JWT token storage)
- flutter_riverpod (DI providers)
- get_it (service locator)
- logger (underlying log library)
- am_analysis_sdk (auto-generated from OpenAPI spec)
- am_design_system (CommonLogger — logging delegation)

## Barrel File (am_library.dart)
- Exports only 8 files
- core/di/service_registry.dart
- core/network/api_client.dart
- core/network/analysis_api_client.dart
- core/network/websocket/am_stomp_client.dart
- core/services/secure_storage_service.dart
- core/errors/api_exception.dart
- core/utils/logger.dart
- core/config/environment.dart
- core/telemetry/telemetry_service.dart

## Files

### api_client.dart (426 lines)
- HTTP client using `http` package (NOT Dio)
- Default base URL: https://am.munish.org
- Methods: get, post, put, delete
- Auth: reads JWT from SecureStorageService on every request
- Fallback: HARDCODED JWT if stored token is null or starts with 'mock_'
- Retry: up to 3 times on 5xx, exponential backoff 1s/2s
- No retry on 4xx except 408 (Request Timeout)
- Telemetry: records every call duration + status to TelemetryService
- Logging: apiRequest() + apiResponse() on every call
- Android: auto-replaces localhost → 10.0.2.2 (emulator fix)
- ApiResponse wrapper: success(data) / error(msg) / isSuccess bool

### am_stomp_client.dart (172 lines)
- WebSocket client using STOMP protocol (stomp_dart_client)
- Protocol layer: STOMP over WebSocket (same as Spring Boot @MessageMapping)
- StompStatus enum: disconnected / connecting / connected / error
- Two rxdart streams
  - BehaviorSubject status (replays latest to new subscribers)
  - PublishSubject messages (only live subscribers receive)
- connect(headers, onConnect, onWebSocketError)
  - Auto-reconnect every 5 seconds if disconnected
  - Connection timeout: 10 seconds
  - JWT injected via headers: {Authorization: Bearer token}
- subscribe(destination, forceResubscribe)
  - Guard: skips if already subscribed (unless forceResubscribe: true)
  - All frames go to shared messages stream — filter by frame.headers['destination']
- send(destination, body, headers)
  - Sends to backend @MessageMapping endpoint
  - e.g. /app/portfolio/calculate
- unsubscribe(destination) — calls stored unsubscribe callback
- disconnect() — deactivates client, clears all subscriptions
- dispose() — closes both rxdart subjects

### analysis_api_client.dart (119 lines)
- Wraps auto-generated am_analysis_sdk ApiClient
- Default base URL: http://localhost:8080 — MUST be overridden
- _AuthClient extends http.BaseClient
  - Clones every request (BaseRequest is not re-sendable after send())
  - Injects Authorization: Bearer token
  - Retry 3x on 5xx (1s, 2s backoff)
  - Passes 4xx to SDK caller without retry
  - Records telemetry per call

### secure_storage_service.dart (86 lines)
- flutter_secure_storage wrapper
- Android: AES encrypted SharedPreferences
- iOS: Keychain
- Web: localStorage (not encrypted)
- Keys: access_token, refresh_token, user_id, user_email, token_expiry
- Methods
  - saveAccessToken / getAccessToken
  - saveRefreshToken / getRefreshToken
  - saveUserId / getUserId
  - saveUserEmail / getUserEmail
  - saveTokenExpiry / getTokenExpiry / isTokenExpired
  - clearAll — wipes everything
  - clearAuthData — clears only auth keys (for logout)

### service_registry.dart (73 lines)
- GetIt-based DI hub
- ServiceRegistry.I = GetIt.instance
- initialize(analysisBaseUrl, wsUrl) — call ONCE in main()
  - Registers: SecureStorageService, TelemetryService, ApiClient, AnalysisApiClient, AmStompClient
  - All registered as lazyLazyRegistered (only created on first access)
  - Guard: if (!I.isRegistered<T>) — safe to call initialize() multiple times
- reset() — clearAuthData() + stomp.disconnect()
- Convenience accessors
  - ServiceRegistry.api → ApiClient
  - ServiceRegistry.analysis → AnalysisApiClient
  - ServiceRegistry.stomp → AmStompClient
  - ServiceRegistry.storage → SecureStorageService
  - ServiceRegistry.telemetry → TelemetryService

### logger.dart (94 lines)
- AppLogger — thin wrapper over am_design_system's CommonLogger
- Levels: debug / info / warning / error
- Environment-aware
  - development: INFO+ enabled
  - preprod: INFO+ enabled
  - production: disabled (silent)
- Methods
  - debug / info / warning / error (message, tag, error, stackTrace)
  - methodEntry(name, params) — logs → method call
  - methodExit(name, result) — logs ← method return
  - apiRequest(method, url, headers, body)
  - apiResponse(method, url, statusCode, duration)
  - userAction(action, context)
  - stateChange(from, to, event)

### environment.dart (112 lines)
- EnvironmentConfig class — static, no instance needed
- Environment enum: development / preprod / production
- Default: production
- All 3 envs currently use same API URL: https://am.munish.org
- Settings per env
  - development: [DEV] title, refreshInterval 30s, enableDebugFeatures true
  - preprod: [PREPROD] title, refreshInterval 60s, enableDebugFeatures true
  - production: AM Investment title, refreshInterval 300s, analyticsEnabled true
- setEnvironment(String env) — switch by string
- Listener system: addListener / removeListener / _notifyListeners
  - Called when environment changes at runtime (for live env switcher UI)

### telemetry_service.dart (66 lines)
- ReplaySubject (last 100 events kept in memory)
- TelemetryType: apiRequest / apiResponse / apiError / wsMessage / wsStatus
- TelemetryEvent: timestamp, type, category, label, statusCode, duration, metadata
- record(event) — add any event manually
- recordApi(category, method, path, statusCode, duration, extra) — convenience
- Both ApiClient and AnalysisApiClient call recordApi on every HTTP call automatically
- Useful for: debug overlays, performance dashboards, error tracking

### api_exception.dart (23 lines)
- ApiException implements Exception
- Fields: message (String), statusCode (int?), data (dynamic)
- statusCode = null means network error (offline / DNS failure)
- statusCode >= 400 means HTTP error from server
- catch syntax: `on ApiException catch (e)`

## WebSocket vs Webhook

### Answer: WebSocket STOMP — No Webhooks in this codebase
- Webhooks need a public HTTP endpoint on the client side — Flutter web has none

### Files Using Real WebSocket

#### STOMP WebSocket (am_library AmStompClient)
- am_library/core/network/websocket/am_stomp_client.dart — core client
- am_portfolio_ui/.../global_portfolio_wrapper.dart
  - Connects on widget initState
  - Sends /app/portfolio/calculate when portfolio selected
- am_portfolio_ui/.../portfolio_cubit.dart
  - Subscribes to /topic/portfolio/{id}
  - Parses StompFrame JSON → emits Cubit state
- am_portfolio_ui/.../portfolio_repository_impl.dart
  - Listens to WS updates in repository layer

#### Raw WebSocket (WebSocketChannel — NOT STOMP)
- am_market/ui/core/services/stream_service.dart
  - Raw WebSocketChannel.connect(Uri.parse(wsUrl))
  - Used for real-time market price tick feed
- am_common/core/network/websocket/am_websocket_client.dart
  - Generic raw WebSocket client (for market module)
- am_common/core/network/websocket/websocket_cubit.dart
  - Cubit managing raw WebSocket connection state

#### am_trade_ui — NO WebSocket at all
- Uses Dart StreamController (broadcast) inside TradeRepositoryImpl
- Write operations trigger REST re-fetch → pushed to stream
- Widgets watching StreamProvider rebuild automatically
- Looks like real-time but is actually REST polling on mutation

## STOMP Flow (Portfolio)
- main() → ServiceRegistry.initialize(wsUrl: wss://am.munish.org/ws-gateway)
- GlobalPortfolioWrapper.initState() → stompClient.connect(headers: JWT)
- onConnect fires → first portfolio auto-selected
- stompClient.send(/app/portfolio/calculate, {userId, portfolioId})
- Backend processes + publishes to topic
- stompClient.subscribe(/topic/portfolio/{id})
- messages stream emits StompFrame → PortfolioCubit parses → UI rebuilds

## Critical Gotchas
- Hardcoded JWT in api_client.dart line 44 — expires and breaks all API calls
- AnalysisApiClient default URL is localhost:8080 — must override in production
- ApiClient uses http package (not Dio) — different from am_trade_ui's client
- Subscribe only INSIDE onConnect callback — not after connect() call
- All STOMP topics share ONE message stream — filter by frame.headers['destination']
- ServiceRegistry.reset() keeps singleton instances — call stomp.configure() for new URL
- initialize() is idempotent — safe to call multiple times due to isRegistered guards
