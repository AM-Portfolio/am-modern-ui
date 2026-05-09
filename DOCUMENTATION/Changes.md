# Market Data UI Fix & Local Development Setup

## The Problem
The frontend "Price Fetch Test" page was failing to display **Open, High, Low, and Close (OHLC)** values. This was happening because the backend API response had transitioned to a flatter JSON structure with different field names (e.g., using `open` instead of `openPrice`).

Additionally, local testing was difficult due to the hardcoded production API URL and the lack of a local development environment (Redis/Backend) in the frontend workspace.

## Key Changes

### 1. UI Field Mapping Fix
Updated the data extraction logic to support both old and new field names for OHLC data and added **Volume** display.

**File**: [price_test_page.dart](file:///c:/Users/ASUS/Desktop/AM-PORTFOLIO/am-modern-ui/am_market/dev/lib/features/developer/price_test_page.dart)

```dart
// Supports both 'openPrice' (old) and 'open' (new flat structure)
_kv(context, "Open", "${data['openPrice'] ?? data['open'] ?? '-'}"),
_kv(context, "High", "${data['highPrice'] ?? data['high'] ?? '-'}"),
_kv(context, "Low", "${data['lowPrice'] ?? data['low'] ?? '-'}"),
_kv(context, "Close", "${data['closePrice'] ?? data['close'] ?? '-'}"),
_kv(context, "Volume", "${data['volume'] ?? '-'}"),
```

### 2. Configurable API Base URL
Made the API base URL configurable at compile-time using Flutter's `dart-define`.

**File**: [market_endpoints.dart](file:///c:/Users/ASUS/Desktop/AM-PORTFOLIO/am-modern-ui/am_market/common/lib/core/constants/market_endpoints.dart)

```dart
static const String baseUrl = String.fromEnvironment(
  'AM_MARKET_BASE_URL',
  defaultValue: 'https://am.asrax.in/market',
);
```

### 3. Developer "Local Host" Toggle
Added a runtime toggle in the Price Test page to quickly switch between the production API and a local backend instance (useful for rapid debugging).

**File**: [price_test_page.dart](file:///c:/Users/ASUS/Desktop/AM-PORTFOLIO/am-modern-ui/am_market/dev/lib/features/developer/price_test_page.dart)

```dart
// Runtime toggle logic
final baseUrl = _useLocal 
    ? 'http://localhost:${_portController.text.trim()}/api' 
    : ApiService.baseUrl;
```

### 4. Unified Local Development (Docker)
Created a unified Docker Compose file to spin up the entire local stack (Backend + Redis + Frontend) with correct networking for browser-to-container communication.

**File**: [docker-compose.local.yml](file:///c:/Users/ASUS/Desktop/AM-PORTFOLIO/docker-compose.local.yml)

- **Backend**: Runs on port `8080`, connected to Redis.
- **Frontend**: Runs on port `9000`, pre-configured to talk to `http://localhost:8080/api`.

---

## How to Test Locally
To verify these changes in a fresh environment:
1. Run `docker compose -f docker-compose.local.yml build --no-cache am-app-ui`
2. Run `docker compose -f docker-compose.local.yml up -d`
3. Access [http://localhost:9000](http://localhost:9000) and use the Price Fetch Test.
