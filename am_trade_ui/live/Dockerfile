# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy dependencies from AM-Repos
COPY AM-Repos/ui/am_modern_ui/am_design_system ./am_design_system
COPY AM-Repos/ui/am_modern_ui/am_common ./am_common
COPY AM-Repos/ui/am_modern_ui/am_auth_ui ./am_auth_ui

# Copy complete modules (trade depends on market)
COPY AM-Repos/ui/am_modern_ui/am_market_ui ./am_market_ui

# Copy external SDK dependency
COPY AM-Repos/backend/am-market/am_market_sdk_flutter ./am_market_sdk_flutter

# Copy complete trade module
COPY AM-Repos/ui/am_modern_ui/am_trade_ui ./am_trade_ui
WORKDIR /app/am_trade_ui/live

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_trade_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
