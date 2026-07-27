# Build/release por canal: pre-prod (dev) o produccion (prod).
# Delega en run-with-maps-key.ps1 (Maps key + dart-defines desde .env.local / .env.prod).
#
# Ejemplos:
#   .\scripts\build-channel.ps1 -Channel preprod -Mode apk
#   .\scripts\build-channel.ps1 -Channel prod -Mode appbundle

param(
  [ValidateSet("preprod", "prod")]
  [string]$Channel = "preprod",

  [ValidateSet("run", "apk", "appbundle")]
  [string]$Mode = "apk",

  [string]$MapsApiKey,
  [string]$BackendBaseUrl,
  [string]$Flavor,
  [string]$Target = "lib/main.dart"
)

$ErrorActionPreference = "Stop"

$environment = if ($Channel -eq "prod") { "prod" } else { "dev" }

Write-Host "Canal: $Channel -> Environment=$environment | Mode=$Mode" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "run-with-maps-key.ps1") `
  -Mode $Mode `
  -Environment $environment `
  -MapsApiKey $MapsApiKey `
  -BackendBaseUrl $BackendBaseUrl `
  -Flavor $Flavor `
  -Target $Target

exit $LASTEXITCODE
