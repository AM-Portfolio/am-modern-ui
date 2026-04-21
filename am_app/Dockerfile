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
RUN for d in am_common am_market/ui am_analysis/ui am_auth_ui am_dashboard_ui am_portfolio_ui am_trade_ui; do \
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

# Build the web application
RUN flutter build web --release

# Staging nginx config for runtime
COPY am_app/nginx.conf /app/nginx.conf

# ── RUNTIME STAGE ────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy built web files from build stage
COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

# Copy nginx configuration from build stage (context-independent)
COPY --from=build-env /app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
