# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# ── CORE MODULES ──────────────────────────────────────────────────────────
COPY am_common/ ./am_common/
COPY am_design_system/ ./am_design_system/
COPY am_library/ ./am_library/

# ── FEATURE MODULES ───────────────────────────────────────────────────────
COPY am_auth_ui/ ./am_auth_ui/
COPY am_market/ ./am_market/
COPY am_portfolio_ui/ ./am_portfolio_ui/
COPY am_trade_ui/ ./am_trade_ui/
COPY am_user_ui/ ./am_user_ui/
COPY am_ai_ui/ ./am_ai_ui/
COPY am_analysis_ui/ ./am_analysis_ui/
COPY am_analysis_core/ ./am_analysis_core/
COPY am_diagnostic_ui/ ./am_diagnostic_ui/

# ── MAIN APPLICATION ─────────────────────────────────────────────────────
# Copy app shell pubspec first for better caching
COPY am_app/pubspec.* ./am_app/
WORKDIR /app/am_app

# Get dependencies for the app shell
RUN flutter pub get

# Copy the rest of the application shell
COPY am_app/ .

# Build the web application
RUN flutter build web --release

# ── RUNTIME STAGE ────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy built web files from build stage
COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY am_app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
