# Verificacion conjunta prod: Firebase JSON + firebase_options + Maps + checklist SMS.
param(
  [ValidateSet("dev", "prod")]
  [string]$Environment = "prod"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

Write-Host "=== Verificacion conjunta pasajero ($Environment) ===" -ForegroundColor Cyan
Write-Host "Firebase + Maps + SMS (Phone Auth)" -ForegroundColor DarkGray
Write-Host ""

$firebaseOk = $true
$mapsOk = $true
$optionsOk = $true

Write-Host "--- Firebase google-services.json ---" -ForegroundColor Cyan
if ($Environment -eq "prod") {
  & (Join-Path $scriptDir "verify-firebase-android-config.ps1") -Flavor prod
} else {
  & (Join-Path $scriptDir "verify-firebase-android-config.ps1") -Flavor dev
}
if ($LASTEXITCODE -ne 0) { $firebaseOk = $false }

Write-Host ""
Write-Host "--- firebase_options.dart vs google-services ---" -ForegroundColor Cyan
& (Join-Path $scriptDir "generate-firebase-options.ps1") -CheckOnly
if ($LASTEXITCODE -ne 0) {
  $optionsOk = $false
  Write-Host "FAIL Ejecuta: .\scripts\generate-firebase-options.ps1" -ForegroundColor Red
} else {
  $optionsPath = Join-Path $repoRoot "lib\firebase_options.dart"
  $optionsText = Get-Content $optionsPath -Raw
  if ($Environment -eq "prod" -and $optionsText -notmatch "prodtexiappgm") {
    Write-Host "FAIL firebase_options.dart no apunta a prodtexiappgm" -ForegroundColor Red
    Write-Host "     Ejecuta: .\scripts\generate-firebase-options.ps1" -ForegroundColor Yellow
    $optionsOk = $false
  } else {
    Write-Host "OK firebase_options alineado" -ForegroundColor Green
  }
}

Write-Host ""
Write-Host "--- Maps ---" -ForegroundColor Cyan
& (Join-Path $scriptDir "verify-maps-rest-key.ps1") -Environment $Environment
if ($LASTEXITCODE -ne 0) { $mapsOk = $false }

Write-Host ""
Write-Host "--- SMS Firebase checklist (consola) ---" -ForegroundColor Cyan
Write-Host "  [ ] Firebase Authentication -> Sign-in method -> Phone -> Enable"
Write-Host "  [ ] Project settings -> app pasajero -> SHA-1 upload (+ SHA-256)"
Write-Host "  [ ] google-services.json descargado de Firebase (oauth_client no vacio)"
Write-Host "  [ ] Build prod: .\scripts\run-with-maps-key.ps1 -Environment prod -Mode apk"
Write-Host ""

Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host ("google-services: " + $(if ($firebaseOk) { "OK" } else { "FAIL" })) -ForegroundColor $(if ($firebaseOk) { "Green" } else { "Red" })
Write-Host ("firebase_options: " + $(if ($optionsOk) { "OK" } else { "FAIL" })) -ForegroundColor $(if ($optionsOk) { "Green" } else { "Red" })
Write-Host ("Maps $Environment`: " + $(if ($mapsOk) { "OK" } else { "FAIL" })) -ForegroundColor $(if ($mapsOk) { "Green" } else { "Red" })

if (-not $firebaseOk -or -not $mapsOk -or -not $optionsOk) { exit 1 }

Write-Host ""
Write-Host "Listo para prueba unificada en dispositivo (mapa + lupa + SMS)." -ForegroundColor Green
Write-Host "Build: .\scripts\run-with-maps-key.ps1 -Environment prod -Mode apk" -ForegroundColor DarkGray
exit 0
