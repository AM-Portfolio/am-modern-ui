#!/bin/bash
# =============================================================================
# Build am-modern-ui Docker image for DEV environment
# =============================================================================
# This script builds the Flutter web app with Dev-specific API URLs baked in.
# Flutter uses compile-time constants (--dart-define), so a separate build
# is required for each environment.
#
# Usage:
#   ./build-dev.sh                    # Build with tag 'dev-latest'
#   ./build-dev.sh v1.2.3             # Build with custom tag
# =============================================================================

set -euo pipefail

IMAGE_TAG="${1:-dev-latest}"
IMAGE_NAME="ghcr.io/am-portfolio/am-modern-ui:${IMAGE_TAG}"

echo "🔨 Building am-modern-ui for DEV environment..."
echo "   Image: ${IMAGE_NAME}"
echo ""

docker build \
  --build-arg AM_API_BASE_URL=https://am-dev.asrax.in/analysis \
  --build-arg AM_AUTH_BASE_URL=https://am-dev.asrax.in/auth \
  --build-arg AM_USER_BASE_URL=https://am-dev.asrax.in/users \
  --build-arg AM_PORTFOLIO_BASE_URL=https://am-dev.asrax.in/portfolio \
  --build-arg AM_TRADE_BASE_URL=https://am-dev.asrax.in/trade \
  --build-arg AM_GMAIL_BASE_URL=https://am-dev.asrax.in/gmail \
  --build-arg AM_MARKET_WS_URL=wss://am-dev.asrax.in/v1/streams \
  --build-arg AM_MARKET_BASE_URL=https://am-dev.asrax.in/market \
  --build-arg AM_ANALYSIS_BASE_URL=https://am-dev.asrax.in/analysis \
  -t "${IMAGE_NAME}" \
  -f am_app/Dockerfile \
  .

echo ""
echo "✅ Build complete: ${IMAGE_NAME}"
echo ""
echo "Next steps:"
echo "  docker push ${IMAGE_NAME}"
echo "  # Then deploy with helm using values.yaml (environment: dev)"
