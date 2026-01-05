# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy dependencies from AM-Repos
COPY AM-Repos/ui/am_modern_ui/am_design_system ./am_design_system
COPY AM-Repos/ui/am_modern_ui/am_common ./am_common
COPY AM-Repos/ui/am_modern_ui/am_auth_ui ./am_auth_ui

# Copy live app
COPY AM-Repos/ui/am_modern_ui/am_portfolio_ui/live ./am_portfolio_ui/live
WORKDIR /app/am_portfolio_ui/live

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_portfolio_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
