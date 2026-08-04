param(
  [ValidateSet("dev", "prod")]
  [string]$Environment = "prod"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

Write-Host "=== Verificacion conjunta ($Environment) ===" -ForegroundColor Cyan
Write-Host "Firebase (google-services.json) + Maps (widget + REST)" -ForegroundColor DarkGray
Write-Host ""

$firebaseScript = Join-Path $scriptDir "verify-firebase-android-config.ps1"
$mapsScript = Join-Path $scriptDir "verify-maps-rest-key.ps1"

if (-not (Test-Path $firebaseScript)) {
  Write-Host "FAIL falta $firebaseScript" -ForegroundColor Red
  exit 1
}
if (-not (Test-Path $mapsScript)) {
  Write-Host "FAIL falta $mapsScript" -ForegroundColor Red
  exit 1
}

$firebaseOk = $true
$mapsOk = $true

Write-Host "--- Firebase ---" -ForegroundColor Cyan
if ($Environment -eq "prod") {
  & $firebaseScript -Flavor prod
} else {
  Write-Host "SKIP Firebase prod (entorno dev; usar flavor prod para humo SMS/FCM prod)" -ForegroundColor DarkGray
}
if ($LASTEXITCODE -ne 0) { $firebaseOk = $false }

Write-Host ""
Write-Host "--- Maps ---" -ForegroundColor Cyan
& $mapsScript -Environment $Environment
if ($LASTEXITCODE -ne 0) { $mapsOk = $false }

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
if ($Environment -eq "prod") {
  Write-Host ("Firebase prod: " + $(if ($firebaseOk) { "OK" } else { "FAIL" })) -ForegroundColor $(if ($firebaseOk) { "Green" } else { "Red" })
} else {
  Write-Host "Firebase prod: SKIP (solo en prod)" -ForegroundColor DarkGray
}
Write-Host ("Maps $Environment`: " + $(if ($mapsOk) { "OK" } else { "FAIL" })) -ForegroundColor $(if ($mapsOk) { "Green" } else { "Red" })

if (-not $firebaseOk -or -not $mapsOk) {
  exit 1
}

Write-Host ""
Write-Host "Listo para build: .\scripts\run-with-maps-key.ps1 -Environment prod -Mode apk" -ForegroundColor Green
exit 0
