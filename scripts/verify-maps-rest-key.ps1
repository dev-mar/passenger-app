param(
  [ValidateSet("dev", "prod")]
  [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

function Get-LocalEnvFilePath {
  param([string]$AppEnvironment)
  $candidates = @(
    (Join-Path $repoRoot ".env.$AppEnvironment.local"),
    (Join-Path $repoRoot ".env.$AppEnvironment"),
    (Join-Path $repoRoot "env.$AppEnvironment.local")
  )
  foreach ($p in $candidates) {
    if (Test-Path $p) { return $p }
  }
  if ($AppEnvironment -eq "dev" -and (Test-Path (Join-Path $repoRoot ".env.local"))) {
    return (Join-Path $repoRoot ".env.local")
  }
  return $null
}

function Get-EnvValueFromFile {
  param([string]$FilePath, [string]$Key)
  if (-not $FilePath -or -not (Test-Path $FilePath)) { return "" }
  foreach ($line in Get-Content $FilePath) {
    if ($line -match "^\s*$Key\s*=\s*(.+)$") {
      return $matches[1].Trim().Trim('"').Trim("'")
    }
  }
  return ""
}

function Test-GoogleMapsRestKey {
  param(
    [string]$KeyLabel,
    [string]$Key,
    [switch]$Optional
  )
  if ([string]::IsNullOrWhiteSpace($Key) -or $Key -like "REEMPLAZA*") {
    if ($Optional) {
      Write-Host "SKIP $KeyLabel - key ausente o placeholder (opcional para widget Android)" -ForegroundColor DarkGray
      return $null
    }
    Write-Host "FAIL $KeyLabel - key ausente o placeholder" -ForegroundColor Red
    return $false
  }
  $geocodeUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=-16.5,-68.15" + "&key=$Key"
  $placesUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=Av+16+de+Julio" + "&components=country:bo" + "&key=$Key"
  $directionsUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=-16.5,-68.15" + "&destination=-16.49,-68.14" + "&key=$Key"

  $geocode = Invoke-RestMethod -Uri $geocodeUrl -TimeoutSec 20
  $places = Invoke-RestMethod -Uri $placesUrl -TimeoutSec 20
  $directions = Invoke-RestMethod -Uri $directionsUrl -TimeoutSec 20

  $ok = ($geocode.status -eq "OK" -or $geocode.status -eq "ZERO_RESULTS") -and
        ($places.status -eq "OK" -or $places.status -eq "ZERO_RESULTS") -and
        ($directions.status -eq "OK")

  if ($ok) {
    Write-Host "OK $KeyLabel - Geocoding=$($geocode.status) Places=$($places.status) Directions=$($directions.status)" -ForegroundColor Green
    return $true
  }

  Write-Host "FAIL $KeyLabel - Geocoding=$($geocode.status) Places=$($places.status) Directions=$($directions.status)" -ForegroundColor Red
  foreach ($r in @($geocode, $places, $directions)) {
    if ($r.error_message) { Write-Host "     $($r.error_message)" -ForegroundColor Yellow }
  }
  if ($geocode.status -eq "REQUEST_DENIED" -or $places.status -eq "REQUEST_DENIED") {
    if ($Optional) {
      Write-Host "     Esperado en prod: key widget restringida a Android apps (mapa nativo OK en dispositivo)." -ForegroundColor DarkGray
    } else {
      Write-Host "     Accion: definir GOOGLE_MAPS_REST_API_KEY sin restriccion Android apps." -ForegroundColor Yellow
    }
  }
  return $false
}

$envFile = Get-LocalEnvFilePath -AppEnvironment $Environment
Write-Host "Verificando Maps REST - entorno: $Environment" -ForegroundColor Cyan
if ($envFile) { Write-Host "Archivo: $(Split-Path $envFile -Leaf)" -ForegroundColor DarkGray }

$mapsKey = Get-EnvValueFromFile -FilePath $envFile -Key "GOOGLE_MAPS_API_KEY"
$restKeyRaw = Get-EnvValueFromFile -FilePath $envFile -Key "GOOGLE_MAPS_REST_API_KEY"
$restKeyDefined = -not [string]::IsNullOrWhiteSpace($restKeyRaw) -and ($restKeyRaw -notlike "REEMPLAZA*")
$restKey = if ($restKeyDefined) { $restKeyRaw } else { "" }

Write-Host ""
Write-Host "[1/2] Widget Android (GOOGLE_MAPS_API_KEY)" -ForegroundColor Cyan
$widgetOptional = ($Environment -eq "prod")
$widgetOk = Test-GoogleMapsRestKey -KeyLabel "GOOGLE_MAPS_API_KEY" -Key $mapsKey -Optional:$widgetOptional

Write-Host ""
Write-Host "[2/2] HTTP REST lupa/rutas (GOOGLE_MAPS_REST_API_KEY)" -ForegroundColor Cyan
if (-not $restKeyDefined) {
  Write-Host "FAIL GOOGLE_MAPS_REST_API_KEY - no definida en $(Split-Path $envFile -Leaf)" -ForegroundColor Red
  Write-Host "     Crear key REST en GCP (Places + Geocoding + Directions, sin restriccion Android apps)." -ForegroundColor Yellow
  Write-Host "     Anadir: GOOGLE_MAPS_REST_API_KEY=... en .env.prod o .env.prod.local" -ForegroundColor Yellow
  $restOk = $false
} else {
  $restOk = Test-GoogleMapsRestKey -KeyLabel "GOOGLE_MAPS_REST_API_KEY" -Key $restKey
}

Write-Host ""
if (-not $restOk) { exit 1 }
if ($widgetOk -eq $false) {
  Write-Host "WARN Key widget fallo REST probe; mapa nativo puede seguir OK con restriccion Android." -ForegroundColor Yellow
}
Write-Host "Listo: lupa y rutas usan GOOGLE_MAPS_REST_API_KEY; widget usa GOOGLE_MAPS_API_KEY." -ForegroundColor Green
exit 0
