# Multi-stage Flutter web build
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

ARG BUILD_ID=local
ENV BUILD_ID=$BUILD_ID

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
COPY am_doc_intelligence_ui/ ./am_doc_intelligence_ui/
COPY am_subscription_ui/ ./am_subscription_ui/

# ── CODE GENERATION ──────────────────────────────────────────────────────
RUN for d in am_common am_design_system am_market/common am_analysis/common am_market/ui am_analysis/ui am_auth_ui am_dashboard_ui am_portfolio_ui am_trade_ui am_doc_intelligence_ui am_subscription_ui; do \
    echo "Generating code for $d..." && \
    cd /app/$d && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs; \
    done

# ── BUILD SCRIPTS + ENV ───────────────────────────────────────────────────
COPY scripts/inject_build_id.sh scripts/docker_build_web.sh /app/scripts/
# .env.preprod is gitignored locally; CI uses the committed example file.
COPY .env.preprod.example /app/.env.preprod

# ── MAIN APPLICATION ─────────────────────────────────────────────────────
COPY am_app/pubspec.* ./am_app/
WORKDIR /app/am_app
RUN flutter pub get

COPY am_app/ .

RUN chmod +x /app/scripts/inject_build_id.sh /app/scripts/docker_build_web.sh && \
    /app/scripts/inject_build_id.sh && \
    /app/scripts/docker_build_web.sh

# ── RUNTIME STAGE ────────────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

COPY am_app/nginx-docker.conf /etc/nginx/nginx-docker.conf
COPY am_app/nginx.profiles/ /etc/nginx/profiles/
COPY am_app/docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh && \
    mkdir -p /tmp/nginx /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    touch /tmp/nginx.pid && \
    chown -R 1000:1000 /tmp/nginx /tmp/nginx.pid /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp /var/cache/nginx /var/log/nginx /usr/share/nginx/html /etc/nginx/profiles

USER 1000

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
