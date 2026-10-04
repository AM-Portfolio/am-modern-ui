# One-time helper: stage Codemagic env group values from local SoT.
# Never commits secrets. Requires CODEMAGIC_API_TOKEN in ~/.asrax/credentials.d/codemagic.env
#
# Sources:
#   ~/.asrax/secrets/keystore_base64.txt
#   ~/.asrax/secrets/key.properties
#   ~/.asrax/credentials.d/apple-developer.env
#   ~/.asrax/secrets/AuthKey_*.p8
#   GitHub secret PLAY_STORE_SERVICE_ACCOUNT_JSON -> CM GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
#
# Codemagic Team UI still required for:
#   - Rename app to AM Flutter Modern UI / archive duplicate
#   - Create ASC integration named exactly Asrax ASC
#   - Create variable groups android_credentials + ios_credentials if missing

$ErrorActionPreference = "Stop"
$secrets = Join-Path $env:USERPROFILE ".asrax\secrets"
$credsD = Join-Path $env:USERPROFILE ".asrax\credentials.d"
$cmEnv = Join-Path $credsD "codemagic.env"
$appleEnv = Join-Path $credsD "apple-developer.env"
$keystoreB64 = Join-Path $secrets "keystore_base64.txt"
$keyProps = Join-Path $secrets "key.properties"
$p8 = Join-Path $secrets "AuthKey_AA5ZK75HAS.p8"

function Load-DotEnv($path) {
  $m = @{}
  if (-not (Test-Path $path)) { return $m }
  Get-Content $path | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
      $m[$Matches[1].Trim()] = $Matches[2].Trim().Trim('"').Trim("'")
    }
  }
  return $m
}

Write-Host "=== Codemagic mobile credential checklist ==="
foreach ($p in @($keystoreB64, $keyProps, $appleEnv, $p8, $cmEnv)) {
  if (Test-Path $p) { Write-Host "OK  $p" } else { Write-Host "MISS $p" }
}

$kp = @{}
if (Test-Path $keyProps) {
  Get-Content $keyProps | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') { $kp[$Matches[1].Trim()] = $Matches[2].Trim() }
  }
}

$apple = Load-DotEnv $appleEnv
$cm = Load-DotEnv $cmEnv

Write-Host ""
Write-Host "Group android_credentials - set in Codemagic UI (Teams / Environment variables):"
Write-Host "  ANDROID_KEYSTORE_BASE64     <- file $keystoreB64"
Write-Host "  ANDROID_KEYSTORE_PASSWORD   <- key.properties storePassword present=$($kp.ContainsKey('storePassword'))"
Write-Host "  ANDROID_KEY_PASSWORD        <- key.properties keyPassword present=$($kp.ContainsKey('keyPassword'))"
Write-Host "  ANDROID_KEY_ALIAS           <- key.properties keyAlias=$($kp['keyAlias'])"
Write-Host "  GCLOUD_SERVICE_ACCOUNT_CREDENTIALS <- GitHub PLAY_STORE_SERVICE_ACCOUNT_JSON (raw JSON)"
Write-Host ""
Write-Host "Group ios_credentials:"
Write-Host "  APP_STORE_CONNECT_KEY_IDENTIFIER = $($apple['APPLE_KEY_ID'])"
Write-Host "  APP_STORE_CONNECT_ISSUER_ID      = $($apple['APPLE_ISSUER_ID'])"
Write-Host "  APP_STORE_CONNECT_PRIVATE_KEY    = PEM text from $p8 (AuthKey contents)"
Write-Host "Optional Team integration name Asrax ASC (not required if env vars set)"
Write-Host ""
Write-Host "Applications UI:"
Write-Host "  Keep app id $($cm['CODEMAGIC_APP_ID']) - rename to: AM Flutter Modern UI"
Write-Host "  Archive the duplicate am-modern-ui application"
Write-Host ""
Write-Host "Optional: fix apple-developer.env APPLE_PRIVATE_KEY_PATH to:"
Write-Host "  $p8"

$stage = Join-Path $env:TEMP "codemagic-mobile-creds-stage"
New-Item -ItemType Directory -Force -Path $stage | Out-Null
if (Test-Path $keystoreB64) {
  (Get-Content -Raw $keystoreB64).Trim() | Set-Content -NoNewline (Join-Path $stage "ANDROID_KEYSTORE_BASE64.txt")
}
if ($kp.ContainsKey('storePassword')) { $kp['storePassword'] | Set-Content -NoNewline (Join-Path $stage "ANDROID_KEYSTORE_PASSWORD.txt") }
if ($kp.ContainsKey('keyPassword')) { $kp['keyPassword'] | Set-Content -NoNewline (Join-Path $stage "ANDROID_KEY_PASSWORD.txt") }
if ($kp.ContainsKey('keyAlias')) { $kp['keyAlias'] | Set-Content -NoNewline (Join-Path $stage "ANDROID_KEY_ALIAS.txt") }
if (Test-Path $p8) { Copy-Item $p8 (Join-Path $stage "AuthKey_AA5ZK75HAS.p8") -Force }
Write-Host ""
Write-Host "Staged copy-paste files (local TEMP only): $stage"
Write-Host "DONE - paste into Codemagic UI, then Start build Android Play Internal / iOS TestFlight"
