# Multi-stage Flutter web build
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Create app directory
WORKDIR /app

# Copy dependencies
COPY ../am_design_system ./am_design_system
COPY ../am_common ./am_common
COPY ../am_auth_ui ./am_auth_ui

# Copy live app
COPY . ./am_market_ui/live
WORKDIR /app/am_market_ui/live

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release --web-renderer canvaskit

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_market_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
