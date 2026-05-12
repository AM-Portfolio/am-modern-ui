# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy dependencies from AM-Repos
COPY AM-Repos/ui/am_modern_ui/am_design_system ./ui/am_modern_ui/am_design_system
COPY AM-Repos/ui/am_modern_ui/am_common ./ui/am_modern_ui/am_common
COPY AM-Repos/ui/am_modern_ui/am_auth_ui ./ui/am_modern_ui/am_auth_ui
COPY AM-Repos/ui/am_modern_ui/am_user_ui ./ui/am_modern_ui/am_user_ui

# Copy complete module (includes lib/ and live/)
COPY AM-Repos/ui/am_modern_ui/am_portfolio_ui ./ui/am_modern_ui/am_portfolio_ui
WORKDIR /app/ui/am_modern_ui/am_portfolio_ui/live

# Define build arguments for API URLs
ARG AM_AUTH_BASE_URL
ARG AM_PORTFOLIO_BASE_URL
ARG AM_TRADE_BASE_URL
ARG AM_MARKET_BASE_URL
ARG AM_ANALYSIS_BASE_URL
ARG AM_DOC_PARSER_BASE_URL
ARG AM_WS_URL

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release \
    --dart-define=AM_AUTH_BASE_URL=${AM_AUTH_BASE_URL} \
    --dart-define=AM_PORTFOLIO_BASE_URL=${AM_PORTFOLIO_BASE_URL} \
    --dart-define=AM_TRADE_BASE_URL=${AM_TRADE_BASE_URL} \
    --dart-define=AM_MARKET_BASE_URL=${AM_MARKET_BASE_URL} \
    --dart-define=AM_ANALYSIS_BASE_URL=${AM_ANALYSIS_BASE_URL} \
    --dart-define=AM_DOC_PARSER_BASE_URL=${AM_DOC_PARSER_BASE_URL} \
    --dart-define=AM_WS_URL=${AM_WS_URL}

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_portfolio_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
