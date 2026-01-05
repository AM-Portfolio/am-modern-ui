# AM Modern UI - Architecture Overview

## Executive Summary

The AM Modern UI is a comprehensive Flutter-based monorepo for investment management, designed with modularity, reusability, and scalability at its core. The architecture follows clean architecture principles with clear separation of concerns across presentation, shared, and infrastructure layers.

## System Architecture

### 📊 Architecture Layers

#### 1. Presentation Layer (Feature Modules)

##### **am_app** - Shell Application
- **Purpose**: Main application orchestrator
- **Features**:
  - Global navigation management
  - Module lifecycle coordination
  - Unified sidebar integration
  - Cross-module routing

##### **am_market_ui** - Market Data Module
- **Purpose**: Real-time market analysis and monitoring
- **Key Features**:
  - Live market indices tracking (30+ indices)
  - Interactive TradingView charts
  - ETF Explorer with detailed analytics
  - Security and instrument search
  - Price validation tools
  - Market analysis dashboards
- **Standalone**: ✅ Available at `am_market_ui/live`

##### **am_portfolio_ui** - Portfolio Management
- **Purpose**: Comprehensive portfolio tracking and analysis
- **Key Features**:
  - Multi-portfolio holdings dashboard
  - Interactive sector heatmaps
  - Performance analytics and P&L tracking
  - Asset allocation visualization
  - Market cap breakdown charts
  - Portfolio comparison tools
- **Standalone**: ✅ Available at `am_portfolio_ui/live`

##### **am_trade_ui** - Trade Management
- **Purpose**: Trade execution, tracking, and journal management
- **Key Features**:
  - Trade entry and execution interface
  - Trade journal with rich text editor
  - Calendar-based trade analytics
  - Performance metrics dashboard
  - Win/Loss ratio tracking
  - Trade report generation
  - Holdings breakdown view
- **Standalone**: ✅ Available at `am_trade_ui/live`

##### **am_user_ui** - User Management
- **Purpose**: User profile and preferences
- **Features**:
  - Profile settings
  - User preferences
  - Account management

#### 2. Shared Layer (Foundation)

##### **am_design_system** - Design Foundation
- **Purpose**: Unified design language and reusable components
- **Components**:
  - **Theme System**: Dark/Light themes, color schemes, typography
  - **Navigation**: Global sidebar, secondary sidebar, swipeable views
  - **Universal Widgets**:
    - Heatmap engine with multiple templates
    - Calendar widgets (monthly, yearly views)
    - Data tables and charts
    - Card components
  - **Module System**: IModule interface, module configurations
  - **Utils**: Logging, device detection, animations

##### **am_auth_ui** - Authentication Module
- **Purpose**: Centralized authentication and authorization
- **Features**:
  - Login/Registration flows
  - Google OAuth integration
  - Demo login mode
  - JWT token management
  - Mock authentication service
  - Secure storage integration
  - AuthWrapper for protected routes

##### **am_common** - Common Utilities
- **Purpose**: Shared business logic and utilities
- **Components**:
  - API client with interceptors
  - Error handling framework
  - Date and string utilities
  - Validators and filters
  - File upload service (Cloudinary integration)
  - Investment data extensions
  - Configuration management

#### 3. Infrastructure Layer

##### Backend Services (Port Allocation)
- **Auth Services**: 8001-8019
  - Token management (8001)
  - User management (8002)
- **Market Data**: 8020-8039
  - Market data API (8020)
- **Trade Management**: 8040-8059
  - Trade API (8040)
- **Portfolio Services**: 8060-8079
  - Portfolio API (8060)

##### Data Storage
- **PostgreSQL**: Primary relational database
- **MongoDB**: Document storage (portfolios, trades)
- **Redis**: Caching layer

##### External Services
- **Cloudinary**: File and image storage

## Standalone Applications

### Production-Ready Live Apps

Each major module has a standalone `live` application for independent deployment:

| App | Path | Port | Status |
|-----|------|------|--------|
| Market Live | `am_market_ui/live` | 9002 | ✅ Production Ready |
| Portfolio Live | `am_portfolio_ui/live` | 9005 | ✅ Production Ready |
| Trade Live | `am_trade_ui/live` | 9006 | ⚠️ Layout Fixes Needed |

### Features
- **Authentication Flow**: Full login integration with dynamic user ID
- **Dependency Injection**: GetIt + Riverpod setup
- **Theme Support**: Dark mode with ThemeCubit
- **Independent Deployment**: Can run without main app shell

## Technology Stack

### Frontend
- **Framework**: Flutter 3.x (Web, iOS, Android, macOS, Windows)
- **State Management**: 
  - Bloc/Cubit for application state
  - Riverpod for dependency injection
- **UI Components**: Custom design system
- **Charts**: fl_chart, TradingView widgets

### Backend Integration
- **HTTP Client**: Dio with interceptors
- **Authentication**: JWT tokens
- **Storage**: SecureStorage for sensitive data

### Development Tools
- **Code Generation**: build_runner, freezed, json_serializable
- **DI**: GetIt, injectable
- **Testing**: flutter_test

## Design Principles

### 1. Modular Architecture
- **Loose Coupling**: Each module is independent
- **Clear Interfaces**: Well-defined contracts between modules
- **Reusability**: Shared components in design system

### 2. Clean Architecture
- **Separation of Concerns**: Presentation, domain, data layers
- **Dependency Rule**: Dependencies flow inward
- **Testability**: Business logic independent of frameworks

### 3. Responsive Design
- **Multi-Platform**: Web, mobile, desktop support
- **Adaptive Layouts**: Different layouts for different screen sizes
- **Accessibility**: Keyboard navigation, screen reader support

### 4. Performance
- **Lazy Loading**: Modules loaded on demand
- **Caching**: Redis for frequently accessed data
- **Optimization**: Image optimization, code splitting

## Deployment Architecture

### Development Environment
```
flutter run -d chrome
```

### Production Deployment
- **Standalone Apps**: Each module can be deployed independently
- **Docker Support**: Containerized deployment (see docker-compose.yml)
- **Port Configuration**: Standardized port allocation across services

## Security

### Authentication
- **JWT Tokens**: Secure token-based authentication
- **Secure Storage**: Platform-specific secure storage
- **OAuth**: Google Sign-In integration

### Authorization
- **Role-Based**: User roles and permissions
- **Route Guards**: AuthWrapper for protected routes

## Future Enhancements

### Planned Features
1. Real-time WebSocket integration for market data
2. Advanced analytics with ML models
3. Multi-currency support
4. Mobile app deployment (iOS/Android)
5. Offline mode with data synchronization

### Technical Debt
1. Trade UI layout issues
2. Comprehensive unit test coverage
3. E2E test automation
4. Performance profiling and optimization

## Repository Structure

```
am_modern_ui/
├── am_app/                 # Main shell application
├── am_auth_ui/            # Authentication module
├── am_common/             # Common utilities
├── am_design_system/      # Design system & components
├── am_market_ui/          # Market data module
│   └── live/              # Standalone market app
├── am_portfolio_ui/       # Portfolio module
│   └── live/              # Standalone portfolio app
├── am_trade_ui/           # Trade module
│   └── live/              # Standalone trade app
├── am_user_ui/            # User profile module
├── docker-compose.yml     # Docker orchestration
└── README.md             # This file
```

## Getting Started

### Prerequisites
- Flutter SDK 3.10.1+
- Dart SDK 3.0+
- Chrome (for web development)

### Setup
```bash
# Clone repository
git clone https://github.com/AM-Portfolio/am-modern-ui.git
cd am_modern_ui

# Run standalone market app
cd am_market_ui/live
flutter pub get
flutter run -d chrome

# Run standalone portfolio app
cd ../../am_portfolio_ui/live
flutter pub get
flutter run -d chrome
```

## License

Copyright © 2026 AM Portfolio. All rights reserved.

---

**Last Updated**: January 5, 2026  
**Version**: 1.0.0  
**Maintained By**: Technical Architecture Team
