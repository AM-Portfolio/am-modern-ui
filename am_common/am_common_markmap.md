# am_common

## Purpose
- Cross-cutting utilities and shared features layer
- Sits between core infrastructure (`am_library`) and feature modules (`am_trade_ui`, etc.)
- Provides global configuration, shared enums, and fully encapsulated sub-features

## Re-exports
- Completely re-exports `am_library` (infrastructure)
- Importing `am_common.dart` gives access to both common utils and core library

## Shared Business Logic
- **Enums**: SectorType, Timeframe, MarketCapType, MetricType
- **Extensions**: InvestmentExtensions

## Configuration System
- **AppConfig**: Master config class holding API configs for all domains
- **UploadConfig**: Cloudinary max sizes (Image 10MB, Doc 50MB, Video 100MB) & folders
- **ConfigService (⚠️ GOTCHA)**
  - Currently a **hardcoded stub**
  - `useMockData` is hardcoded to `true`
  - Base URLs are hardcoded to `localhost`
  - *Must be refactored before production*

## Market Data & WebSockets
- **AMWebSocketClient**
  - Raw WebSocket implementation (NOT STOMP)
  - Auto-reconnects every 5s
- **PriceService**
  - Singleton managing live price ticks
  - Connects raw WS to `MarketDataConfig.wsUrl`
  - Subscribes via **REST HTTP POST** to `/v1/market-data/stream/connect`
  - Broadcasts full cache (`priceStream`) and individual ticks (`updateStream`)
- **WebSocketCubit**
  - Bridges raw WS connection status to BLoC state

## Shared Features

### Attachment (Cloudinary)
- **Service**: `CloudinaryUploadService`
  - Handles Web (base64 from UI) and Mobile (reads bytes -> base64)
  - Uploads base64 string to backend repository proxy
- **Config**: Defined folders per feature (`journal`, `portfolio`, `trade`, etc.)
- **Widgets**: `AttachmentPicker`, `SharedAttachmentSection`

### Notifications
- **Provider**: `NotificationNotifier` (Riverpod)
- **State**: `NotificationState` (List of `NotificationEntity`, unread count)
- **Data (⚠️ GOTCHA)**: Currently uses a hardcoded 1-second delay returning **Mock Data** ("Welcome", "Basket Opportunity")
- **Widgets**: `NotificationBell`

## Dependency Injection
- `network_providers.dart` (Riverpod)
- `appConfigProvider`: Awaits `ConfigService.initialize()`
- `apiClientProvider`: Uses `am_library`'s ApiClient
- Specific API config providers (`portfolioApiConfigProvider`, etc.)
