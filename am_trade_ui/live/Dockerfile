# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy dependencies from AM-Repos
COPY AM-Repos/ui/am_modern_ui/am_design_system ./ui/am_modern_ui/am_design_system
COPY AM-Repos/ui/am_modern_ui/am_common ./ui/am_modern_ui/am_common
COPY AM-Repos/ui/am_modern_ui/am_auth_ui ./ui/am_modern_ui/am_auth_ui
COPY AM-Repos/ui/am_modern_ui/am_portfolio_ui ./ui/am_modern_ui/am_portfolio_ui
COPY AM-Repos/ui/am_modern_ui/am_market_ui ./ui/am_modern_ui/am_market_ui
COPY AM-Repos/ui/am_modern_ui/am_user_ui ./ui/am_modern_ui/am_user_ui

# Copy external SDK dependency
COPY AM-Repos/backend/am-market/am_market_sdk_flutter ./backend/am-market/am_market_sdk_flutter

# Copy complete module (includes lib/ and live/)
COPY AM-Repos/ui/am_modern_ui/am_trade_ui ./ui/am_modern_ui/am_trade_ui
WORKDIR /app/ui/am_modern_ui/am_trade_ui/live

# Environment variables for API endpoints
ARG AM_API_BASE_URL=https://am.munish.org
ARG AM_AUTH_BASE_URL=https://am.munish.org/auth
ARG AM_USER_BASE_URL=https://am.munish.org/users
ARG AM_PORTFOLIO_BASE_URL=https://am.munish.org/portfolio
ARG AM_TRADE_BASE_URL=https://am.munish.org/trade
ARG AM_GMAIL_BASE_URL=https://am.munish.org/gmail
ARG AM_MARKET_WS_URL=wss://am.munish.org/ws
ARG AM_MARKET_BASE_URL=https://am.munish.org/market
ARG AM_ANALYSIS_BASE_URL=https://am.munish.org/analysis
ARG AM_ENVIRONMENT=production
ARG AM_USE_MOCK_DATA=false

# Get dependencies
RUN flutter pub get

# Build web app with environment configuration
RUN flutter build web --release \
    --dart-define=AM_API_BASE_URL=$AM_API_BASE_URL \
    --dart-define=AM_AUTH_BASE_URL=$AM_AUTH_BASE_URL \
    --dart-define=AM_USER_BASE_URL=$AM_USER_BASE_URL \
    --dart-define=AM_PORTFOLIO_BASE_URL=$AM_PORTFOLIO_BASE_URL \
    --dart-define=AM_TRADE_BASE_URL=$AM_TRADE_BASE_URL \
    --dart-define=AM_GMAIL_BASE_URL=$AM_GMAIL_BASE_URL \
    --dart-define=AM_MARKET_WS_URL=$AM_MARKET_WS_URL \
    --dart-define=AM_MARKET_BASE_URL=$AM_MARKET_BASE_URL \
    --dart-define=AM_ANALYSIS_BASE_URL=$AM_ANALYSIS_BASE_URL \
    --dart-define=AM_ENVIRONMENT=$AM_ENVIRONMENT \
    --dart-define=AM_USE_MOCK_DATA=$AM_USE_MOCK_DATA

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_trade_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
