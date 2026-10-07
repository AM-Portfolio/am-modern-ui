# Start + poll Codemagic store workflows from local (no GitHub).
# Auth: ~/.asrax/credentials.d/codemagic.env
#
# Usage:
#   .\scripts\ci\cm-store-test.ps1 -Workflow android-play-internal
#   .\scripts\ci\cm-store-test.ps1 -Workflow ios-testflight
#   .\scripts\ci\cm-store-test.ps1 -Workflow both
#
# iOS tip yaml requires Team Developer Portal integration named exactly "Asrax ASC".
# Rename in Codemagic UI if builds fail with integration-does-not-exist.

param(
  [ValidateSet("android-play-internal", "ios-testflight", "both")]
  [string]$Workflow = "both",
  [string]$Branch = "feature/ios-prod-testing",
  [int]$PollSeconds = 30,
  [int]$TimeoutMinutes = 90
)

$ErrorActionPreference = "Stop"
$api = "https://api.codemagic.io"

function Load-DotEnv([string]$path) {
  $m = @{}
  if (-not (Test-Path $path)) { return $m }
  Get-Content $path | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
      $m[$Matches[1].Trim()] = $Matches[2].Trim().Trim('"').Trim("'")
    }
  }
  return $m
}

$cm = Load-DotEnv (Join-Path $env:USERPROFILE ".asrax\credentials.d\codemagic.env")
$token = $cm["CODEMAGIC_API_TOKEN"]
$appId = $cm["CODEMAGIC_APP_ID"]
if (-not $token -or -not $appId) {
  throw "CODEMAGIC_API_TOKEN / CODEMAGIC_APP_ID missing in ~/.asrax/credentials.d/codemagic.env"
}

$headers = @{
  "Content-Type" = "application/json"
  "x-auth-token" = $token
  Accept         = "application/json"
}

function Start-CmBuild([string]$workflowId) {
  $body = @{
    appId      = $appId
    workflowId = $workflowId
    branch     = $Branch
  } | ConvertTo-Json -Compress
  Write-Host "Starting $workflowId on $Branch ..."
  $resp = Invoke-RestMethod -Method Post -Uri "$api/builds" -Headers $headers -Body $body
  if (-not $resp.buildId) { throw "No buildId in response: $($resp | ConvertTo-Json -Compress)" }
  Write-Host "  buildId=$($resp.buildId)"
  Write-Host "  https://codemagic.io/app/$appId/build/$($resp.buildId)"
  return $resp.buildId
}

function Get-CmBuild([string]$buildId) {
  return Invoke-RestMethod -Uri "$api/builds/$buildId" -Headers $headers
}

function Get-BuildSummary($payload) {
  # api.codemagic.io/builds/:id returns { build: {...} } or nested shapes
  $b = $null
  if ($payload.build) { $b = $payload.build }
  elseif ($payload.status) { $b = $payload }
  else {
    # sometimes { builds: [ ... ] } single
    if ($payload.builds) { $b = @($payload.builds)[0] }
  }
  if (-not $b) { return @{ status = "unknown"; message = ($payload | ConvertTo-Json -Compress) } }

  $status = $b.status
  $msg = $b.message
  if (-not $msg -and $b.error) { $msg = $b.error }
  if (-not $msg -and $b.failureReason) { $msg = $b.failureReason }
  $wf = $b.fileWorkflowId
  if (-not $wf) { $wf = $b.workflowId }
  return @{
    status     = "$status"
    message    = "$msg"
    workflowId = "$wf"
    branch     = "$($b.branch)"
    startedAt  = "$($b.startedAt)"
    finishedAt = "$($b.finishedAt)"
  }
}

function Wait-CmBuild([string]$buildId) {
  $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
  $terminal = @("finished", "failed", "canceled", "timeout", "skipped")
  while ((Get-Date) -lt $deadline) {
    $raw = Get-CmBuild $buildId
    $s = Get-BuildSummary $raw
    $st = $s.status.ToLowerInvariant()
    Write-Host ("[{0:HH:mm:ss}] {1} status={2} msg={3}" -f (Get-Date), $buildId, $s.status, $s.message)
    if ($terminal -contains $st) {
      return $s
    }
    Start-Sleep -Seconds $PollSeconds
  }
  throw "Timeout waiting for build $buildId after $TimeoutMinutes minutes"
}

$workflows = @()
if ($Workflow -eq "both") {
  $workflows = @("android-play-internal", "ios-testflight")
} else {
  $workflows = @($Workflow)
}

$results = @()
foreach ($wf in $workflows) {
  Write-Host ""
  Write-Host "==== $wf ===="
  $id = Start-CmBuild $wf
  $summary = Wait-CmBuild $id
  $ok = ($summary.status.ToLowerInvariant() -eq "finished")
  $results += [pscustomobject]@{
    Workflow = $wf
    BuildId  = $id
    Status   = $summary.status
    Message  = $summary.message
    Ok       = $ok
    Url      = "https://codemagic.io/app/$appId/build/$id"
  }
  if (-not $ok) {
    Write-Host "FAILED $wf : $($summary.message)" -ForegroundColor Red
    if ($summary.message -match 'Asrax ASC') {
      Write-Host @"

UI fix required (no git commit):
  Codemagic → Team settings → Integrations → Developer Portal
  Rename API key reference to exactly: Asrax ASC
Then re-run: .\scripts\ci\cm-store-test.ps1 -Workflow ios-testflight
"@ -ForegroundColor Yellow
    }
  } else {
    Write-Host "OK $wf finished" -ForegroundColor Green
  }
}

Write-Host ""
Write-Host "==== Summary ===="
$results | Format-Table -AutoSize | Out-String | Write-Host

$failed = @($results | Where-Object { -not $_.Ok })
if ($failed.Count -gt 0) {
  exit 1
}
Write-Host "All requested Codemagic store workflows finished successfully."
exit 0
