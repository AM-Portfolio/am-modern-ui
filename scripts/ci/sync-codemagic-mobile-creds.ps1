# Push local mobile SoT into Codemagic application variable groups via REST API.
# Never commits secrets. Idempotent: deletes existing names then recreates.
#
# Sources:
#   ~/.asrax/secrets/keystore_base64.txt
#   ~/.asrax/secrets/key.properties
#   ~/.asrax/credentials.d/apple-developer.env
#   ~/.asrax/secrets/AuthKey_AA5ZK75HAS.p8
#   Optional: ~/.asrax/secrets/play-store-service-account.json -> GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
#     (or set env PLAY_STORE_SERVICE_ACCOUNT_JSON before running)
#
# Requires: CODEMAGIC_API_TOKEN + CODEMAGIC_APP_ID in ~/.asrax/credentials.d/codemagic.env

$ErrorActionPreference = "Stop"
$secrets = Join-Path $env:USERPROFILE ".asrax\secrets"
$credsD = Join-Path $env:USERPROFILE ".asrax\credentials.d"
$cmEnv = Join-Path $credsD "codemagic.env"
$appleEnv = Join-Path $credsD "apple-developer.env"
$keystoreB64Path = Join-Path $secrets "keystore_base64.txt"
$keyProps = Join-Path $secrets "key.properties"
$p8 = Join-Path $secrets "AuthKey_AA5ZK75HAS.p8"
$playPath = Join-Path $secrets "play-store-service-account.json"
$apiBase = "https://codemagic.io/api/v3"

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

$cm = Load-DotEnv $cmEnv
$tok = $cm["CODEMAGIC_API_TOKEN"]
$app = $cm["CODEMAGIC_APP_ID"]
if (-not $tok -or -not $app) { throw "CODEMAGIC_API_TOKEN / CODEMAGIC_APP_ID missing in $cmEnv" }

$h = @{ "x-auth-token" = $tok; Accept = "application/json"; "Content-Type" = "application/json" }

function Cm-Get($url) { Invoke-RestMethod -Uri $url -Headers $h }
function Cm-Post($url, $obj) {
  $json = $obj | ConvertTo-Json -Depth 10 -Compress
  Invoke-RestMethod -Method Post -Uri $url -Headers $h -Body $json
}
function Cm-Delete($url) {
  try {
    Invoke-RestMethod -Method Delete -Uri $url -Headers $h | Out-Null
  } catch {
    # 404 = already gone
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -ne 404) { throw }
  }
}

function Ensure-Group([string]$name) {
  $list = Cm-Get "$apiBase/apps/$app/variable-groups"
  $items = @()
  if ($list.data) { $items = @($list.data) }
  $found = $items | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if ($found) { return $found.id }
  $created = Cm-Post "$apiBase/apps/$app/variable-groups" @{ name = $name }
  return $created.data.id
}

function Set-GroupVars([string]$groupId, [array]$vars) {
  $existing = Cm-Get "$apiBase/variable-groups/$groupId/variables"
  $want = @{}
  foreach ($v in $vars) { $want[$v.name] = $true }
  foreach ($ev in @($existing.data)) {
    if ($want.ContainsKey($ev.name)) {
      Cm-Delete "$apiBase/variable-groups/$groupId/variables/$($ev.id)"
    }
  }
  Cm-Post "$apiBase/variable-groups/$groupId/variables" @{
    secure = $true
    variables = @($vars | ForEach-Object { @{ name = $_.name; value = $_.value } })
  } | Out-Null
}

# Load values
if (-not (Test-Path $keystoreB64Path)) { throw "Missing $keystoreB64Path" }
if (-not (Test-Path $keyProps)) { throw "Missing $keyProps" }
if (-not (Test-Path $p8)) { throw "Missing $p8" }

$keystoreB64 = ((Get-Content -Raw $keystoreB64Path) -replace "\s", "")
$kp = @{}
Get-Content $keyProps | ForEach-Object {
  if ($_ -match '^\s*([^=]+)=(.*)$') { $kp[$Matches[1].Trim()] = $Matches[2].Trim() }
}
$apple = Load-DotEnv $appleEnv
$p8Pem = (Get-Content -Raw $p8).Trim()

$playJson = $env:PLAY_STORE_SERVICE_ACCOUNT_JSON
if (-not $playJson -and (Test-Path $playPath)) {
  $playJson = Get-Content -Raw $playPath
}

Write-Host "Pushing to Codemagic app $app ..."
$androidId = Ensure-Group "android_credentials"
$iosId = Ensure-Group "ios_credentials"
Write-Host "  android_credentials = $androidId"
Write-Host "  ios_credentials     = $iosId"

$androidVars = @(
  @{ name = "ANDROID_KEYSTORE_BASE64"; value = $keystoreB64 },
  @{ name = "ANDROID_KEYSTORE_PASSWORD"; value = $kp["storePassword"] },
  @{ name = "ANDROID_KEY_PASSWORD"; value = $kp["keyPassword"] },
  @{ name = "ANDROID_KEY_ALIAS"; value = $kp["keyAlias"] }
)
if ($playJson) {
  $androidVars += @{ name = "GCLOUD_SERVICE_ACCOUNT_CREDENTIALS"; value = $playJson.Trim() }
  Write-Host "  + GCLOUD_SERVICE_ACCOUNT_CREDENTIALS"
} else {
  Write-Host "  WARN: Play SA JSON not found. Save GitHub PLAY_STORE_SERVICE_ACCOUNT_JSON to:"
  Write-Host "        $playPath"
  Write-Host "        or set env PLAY_STORE_SERVICE_ACCOUNT_JSON then re-run this script."
}

Set-GroupVars $androidId $androidVars
Set-GroupVars $iosId @(
  @{ name = "APP_STORE_CONNECT_KEY_IDENTIFIER"; value = $apple["APPLE_KEY_ID"] },
  @{ name = "APP_STORE_CONNECT_API_KEY_ID"; value = $apple["APPLE_KEY_ID"] },
  @{ name = "APP_STORE_CONNECT_ISSUER_ID"; value = $apple["APPLE_ISSUER_ID"] },
  @{ name = "APP_STORE_CONNECT_PRIVATE_KEY"; value = $p8Pem }
)

# Verify names present (values are null when secure)
$av = Cm-Get "$apiBase/variable-groups/$androidId/variables"
$iv = Cm-Get "$apiBase/variable-groups/$iosId/variables"
Write-Host "android vars: $((@($av.data) | ForEach-Object { $_.name }) -join ', ')"
Write-Host "ios vars:     $((@($iv.data) | ForEach-Object { $_.name }) -join ', ')"
Write-Host "DONE - open https://codemagic.io/app/$app/settings to confirm groups on AM Flutter Modern UI"
Write-Host "Then Start build: Android CI AAB (signed) or Android Play Internal / iOS TestFlight"
