# Instala google-services.json oficial de Firebase (prodtexiappgm) en flavor prod.
# Acepta JSON multi-app (conductor + pasajero): Gradle/scripts eligen bloque por package_name.
param(
  [Parameter(Mandatory = $true)]
  [string]$SourcePath,

  [switch]$FromDownloads
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$destPath = Join-Path $repoRoot "android\app\src\prod\google-services.json"
$expectedProjectId = "prodtexiappgm"
$expectedPassengerPackage = "com.taxitexi.texi_passenger_app"

if ($FromDownloads) {
  $SourcePath = Join-Path $env:USERPROFILE "Downloads\google-services.json"
}

if (-not (Test-Path $SourcePath)) {
  Write-Host "FAIL No existe: $SourcePath" -ForegroundColor Red
  exit 1
}

$json = Get-Content $SourcePath -Raw | ConvertFrom-Json
$projectId = $json.project_info.project_id
if ($projectId -ne $expectedProjectId) {
  Write-Host "FAIL project_id=$projectId (se esperaba $expectedProjectId)" -ForegroundColor Red
  Write-Host "     Descarga desde Firebase Console -> prodtexiappgm -> Project settings." -ForegroundColor Yellow
  exit 1
}

$passenger = $null
foreach ($c in @($json.client)) {
  if ($c.client_info.android_client_info.package_name -eq $expectedPassengerPackage) {
    $passenger = $c
    break
  }
}
if ($null -eq $passenger) {
  Write-Host "FAIL Sin bloque $expectedPassengerPackage en el JSON" -ForegroundColor Red
  exit 1
}
if (@($passenger.oauth_client).Count -eq 0) {
  Write-Host "FAIL Bloque pasajero sin oauth_client (Phone Auth / Google Sign-In no funcionaran)" -ForegroundColor Red
  exit 1
}

$clientCount = @($json.client).Count
if ($clientCount -gt 1) {
  Write-Host "OK JSON multi-app ($clientCount bloques). Solo se usa el bloque pasajero en este repo." -ForegroundColor DarkGray
}

Copy-Item -Path $SourcePath -Destination $destPath -Force
Write-Host "OK Instalado en: $destPath" -ForegroundColor Green

& (Join-Path $PSScriptRoot "generate-firebase-options.ps1")
& (Join-Path $PSScriptRoot "verify-firebase-android-config.ps1") -Flavor prod
