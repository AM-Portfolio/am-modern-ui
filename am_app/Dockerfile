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

# Copy all module dependencies first
COPY am_design_system ./am_design_system
COPY am_common ./am_common
COPY am_auth_ui ./am_auth_ui
COPY am_market_ui ./am_market_ui
COPY am_portfolio_ui ./am_portfolio_ui
COPY am_trade_ui ./am_trade_ui
COPY am_user_ui ./am_user_ui

# Copy app files
COPY am_app/pubspec.* ./am_app/
WORKDIR /app/am_app

# Get dependencies
RUN flutter pub get

# Copy rest of app
COPY am_app .

# Build web app
RUN flutter build web --release --web-renderer canvaskit

# Runtime stage - nginx
FROM nginx:alpine

# Copy built web files
COPY --from=build-env /app/am_app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY am_app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
