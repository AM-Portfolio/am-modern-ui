# =============================================================================
# Build am-modern-ui Docker image (host-free)
# =============================================================================
# The image does not bake AM_DOMAIN / AM_*_BASE_URL. After push, deploy with
# Helm values.{env}.yaml so config.json supplies the gateway domain at runtime.
#
# Usage:
#   .\build-dev.ps1                   # Build with tag 'dev-latest'
#   .\build-dev.ps1 -Tag "v1.2.3"    # Build with custom tag
# =============================================================================

param(
    [string]$Tag = "dev-latest"
)

$ImageName = "ghcr.io/am-portfolio/am-modern-ui:$Tag"

Write-Host "Building am-modern-ui (runtime config via Helm)..." -ForegroundColor Cyan
Write-Host "   Image: $ImageName" -ForegroundColor Yellow

docker build `
  -t $ImageName `
  -f am_app/Dockerfile `
  .

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild complete: $ImageName" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  docker push $ImageName"
    Write-Host "  # Deploy with helm values.dev.yaml / values.preprod.yaml / values.prod.yaml"
    Write-Host "  # Host comes from appConfig.domain in those values (not from this build)."
} else {
    Write-Host "`nBuild FAILED!" -ForegroundColor Red
    exit $LASTEXITCODE
}
