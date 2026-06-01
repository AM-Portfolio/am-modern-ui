# =============================================================================
# Build am-modern-ui Docker image for DEV environment
# =============================================================================
# Flutter uses compile-time constants (--dart-define), so a separate build
# is required for each environment.
#
# Usage:
#   .\build-dev.ps1                   # Build with tag 'dev-latest'
#   .\build-dev.ps1 -Tag "v1.2.3"    # Build with custom tag
# =============================================================================

param(
    [string]$Tag = "dev-latest"
)

$ImageName = "ghcr.io/am-portfolio/am-modern-ui:$Tag"

Write-Host "Building am-modern-ui for DEV environment..." -ForegroundColor Cyan
Write-Host "   Image: $ImageName" -ForegroundColor Yellow

docker build `
  --build-arg AM_API_BASE_URL=https://am-dev.asrax.in/analysis `
  --build-arg AM_AUTH_BASE_URL=https://am-dev.asrax.in/auth `
  --build-arg AM_USER_BASE_URL=https://am-dev.asrax.in/users `
  --build-arg AM_PORTFOLIO_BASE_URL=https://am-dev.asrax.in/portfolio `
  --build-arg AM_TRADE_BASE_URL=https://am-dev.asrax.in/trade `
  --build-arg AM_GMAIL_BASE_URL=https://am-dev.asrax.in/gmail `
  --build-arg AM_MARKET_WS_URL=wss://am-dev.asrax.in/v1/streams `
  --build-arg AM_MARKET_BASE_URL=https://am-dev.asrax.in/market `
  --build-arg AM_ANALYSIS_BASE_URL=https://am-dev.asrax.in/analysis `
  -t $ImageName `
  -f am_app/Dockerfile `
  .

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild complete: $ImageName" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  docker push $ImageName"
    Write-Host "  # Then deploy with helm using values.yaml (environment: dev)"
} else {
    Write-Host "`nBuild FAILED!" -ForegroundColor Red
    exit $LASTEXITCODE
}
