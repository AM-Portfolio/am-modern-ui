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
COPY am_dashboard_ui/ ./am_dashboard_ui/
COPY am_market/ ./am_market/
COPY am_portfolio_ui/ ./am_portfolio_ui/
COPY am_trade_ui/ ./am_trade_ui/
COPY am_user_ui/ ./am_user_ui/
COPY am_ai_ui/ ./am_ai_ui/
COPY am_analysis/ ./am_analysis/
COPY am_diagnostic_ui/ ./am_diagnostic_ui/

# ── CODE GENERATION ──────────────────────────────────────────────────────
# Generate code for all modules that use build_runner
RUN for d in am_common am_design_system am_market/common am_analysis/common am_market/ui am_analysis/ui am_auth_ui am_dashboard_ui am_portfolio_ui am_trade_ui; do \
    echo "Generating code for $d..." && \
    cd /app/$d && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs; \
    done

# ── MAIN APPLICATION ─────────────────────────────────────────────────────
# Copy app shell pubspec first for better caching
COPY am_app/pubspec.* ./am_app/
WORKDIR /app/am_app

# Get dependencies for the app shell
RUN flutter pub get

# Copy the rest of the application shell
COPY am_app/ .

# Build-time API configuration
ARG AM_API_BASE_URL=https://am.asrax.in
ARG AM_AUTH_BASE_URL=https://am.asrax.in/auth
ARG AM_USER_BASE_URL=https://am.asrax.in/users
ARG AM_PORTFOLIO_BASE_URL=https://am.asrax.in/portfolio
ARG AM_TRADE_BASE_URL=https://am.asrax.in/trade
ARG AM_GMAIL_BASE_URL=https://am.asrax.in/gmail
ARG AM_MARKET_WS_URL=wss://am.asrax.in/ws
ARG AM_MARKET_BASE_URL=https://am.asrax.in/market
ARG AM_ANALYSIS_BASE_URL=https://am.asrax.in/analysis

# Additional configuration
ARG AM_GOOGLE_CLIENT_ID=your-client-id
ARG AM_USE_MOCK_DATA=false
ARG AM_DEV_TOKEN=""
ARG AM_DEV_USER_ID=""

# Build the web application
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
    --dart-define=AM_GOOGLE_CLIENT_ID=$AM_GOOGLE_CLIENT_ID \
    --dart-define=AM_USE_MOCK_DATA=$AM_USE_MOCK_DATA \
    --dart-define=AM_DEV_TOKEN=$AM_DEV_TOKEN \
    --dart-define=AM_DEV_USER_ID=$AM_DEV_USER_ID

# Staging nginx config for runtime
COPY am_app/nginx.conf /app/nginx.conf

# ── RUNTIME STAGE ────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy built web files from build stage
COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

# Copy nginx configuration from build stage (context-independent)
COPY --from=build-env /app/nginx.conf /etc/nginx/conf.d/default.conf

# Support non-root execution (satisfies runAsNonRoot: true)
# Ensure nginx can write to cache, pid and run directories as UID 1000
RUN touch /var/run/nginx.pid && \
    chown -R 1000:1000 /var/run/nginx.pid /var/cache/nginx /var/log/nginx /usr/share/nginx/html

# Expose port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
