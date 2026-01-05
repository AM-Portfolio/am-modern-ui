# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy all module dependencies from AM-Repos
COPY AM-Repos/am_modern_ui/am_design_system ./am_design_system
COPY AM-Repos/am_modern_ui/am_common ./am_common
COPY AM-Repos/am_modern_ui/am_auth_ui ./am_auth_ui
COPY AM-Repos/am_modern_ui/am_market_ui ./am_market_ui
COPY AM-Repos/am_modern_ui/am_portfolio_ui ./am_portfolio_ui
COPY AM-Repos/am_modern_ui/am_trade_ui ./am_trade_ui
COPY AM-Repos/am_modern_ui/am_user_ui ./am_user_ui

# Copy external SDK dependency
COPY AM-Repos/am-market/am_market_sdk_flutter ./am_market_sdk_flutter

# Copy app files
COPY AM-Repos/am_modern_ui/am_app/pubspec.* ./am_app/
WORKDIR /app/am_app

# Get dependencies
RUN flutter pub get

# Copy rest of app
COPY AM-Repos/am_modern_ui/am_app .

# Build web app
RUN flutter build web --release

# Runtime stage - nginx
FROM nginx:alpine

# Copy built web files
COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY AM-Repos/am_modern_ui/am_app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
