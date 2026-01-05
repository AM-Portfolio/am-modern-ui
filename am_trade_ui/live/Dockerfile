# Multi-stage Flutter web build
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter repository
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web
RUN flutter config --enable-web

# Run flutter doctor
RUN flutter doctor -v

# Create app directory
WORKDIR /app

# Copy dependencies
COPY ../am_design_system ./am_design_system
COPY ../am_common ./am_common
COPY ../am_auth_ui ./am_auth_ui
COPY ../am_market_ui ./am_market_ui

# Copy live app
COPY . ./am_trade_ui/live
WORKDIR /app/am_trade_ui/live

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release --web-renderer canvaskit

# Runtime stage
FROM nginx:alpine

# Copy built files
COPY --from=build-env /app/am_trade_ui/live/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
