param(
  [ValidateSet("run", "apk")]
  [string]$Mode = "run",

  [string]$MapsApiKey,

  [string]$BackendBaseUrl,

  [string]$Flavor,

  [string]$Target = "lib/main.dart"
)

$ErrorActionPreference = "Stop"

function Get-EnvValueFromLocalFile {
  param(
    [string]$FilePath,
    [string]$Key
  )

  if (-not (Test-Path $FilePath)) {
    return ""
  }

  $lines = Get-Content -Path $FilePath -ErrorAction SilentlyContinue
  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
    if ($trimmed.StartsWith("#")) { continue }
    if (-not $trimmed.Contains("=")) { continue }

    $parts = $trimmed.Split("=", 2)
    $currentKey = $parts[0].Trim()
    $currentValue = $parts[1].Trim()
    if ($currentKey -ne $Key) { continue }

    if (
      ($currentValue.StartsWith('"') -and $currentValue.EndsWith('"')) -or
      ($currentValue.StartsWith("'") -and $currentValue.EndsWith("'"))
    ) {
      return $currentValue.Substring(1, $currentValue.Length - 2).Trim()
    }
    return $currentValue
  }

  return ""
}

function Resolve-MapsKey {
  param([string]$FromParam)

  if (-not [string]::IsNullOrWhiteSpace($FromParam)) {
    return $FromParam.Trim()
  }

  if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_MAPS_API_KEY)) {
    return $env:GOOGLE_MAPS_API_KEY.Trim()
  }

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $envLocalPath = Join-Path $repoRoot ".env.local"
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "GOOGLE_MAPS_API_KEY"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim()
  }

  return ""
}

function Resolve-BackendBaseUrl {
  param([string]$FromParam)

  if (-not [string]::IsNullOrWhiteSpace($FromParam)) {
    return $FromParam.Trim()
  }

  if (-not [string]::IsNullOrWhiteSpace($env:TEXI_BACKEND_BASE_URL)) {
    return $env:TEXI_BACKEND_BASE_URL.Trim()
  }

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $envLocalPath = Join-Path $repoRoot ".env.local"
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "TEXI_BACKEND_BASE_URL"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim()
  }

  return ""
}

$resolvedKey = Resolve-MapsKey -FromParam $MapsApiKey
$resolvedBackend = Resolve-BackendBaseUrl -FromParam $BackendBaseUrl

if ([string]::IsNullOrWhiteSpace($resolvedKey)) {
  Write-Host ""
  Write-Host "Falta GOOGLE_MAPS_API_KEY." -ForegroundColor Red
  Write-Host "Opciones:" -ForegroundColor Yellow
  Write-Host "  1) Pasar por parametro: -MapsApiKey ""TU_KEY"""
  Write-Host "  2) Exportar variable: `$env:GOOGLE_MAPS_API_KEY=""TU_KEY"""
  Write-Host "  3) Guardar en .env.local: GOOGLE_MAPS_API_KEY=TU_KEY"
  Write-Host ""
  Write-Host "Ejemplos:"
  Write-Host "  .\scripts\run-with-maps-key.ps1 -Mode run -MapsApiKey ""TU_KEY"""
  Write-Host "  .\scripts\run-with-maps-key.ps1 -Mode apk -MapsApiKey ""TU_KEY"""
  exit 1
}

$env:GOOGLE_MAPS_API_KEY = $resolvedKey
if (-not [string]::IsNullOrWhiteSpace($resolvedBackend)) {
  $env:TEXI_BACKEND_BASE_URL = $resolvedBackend
}

$flutterArgs = @()
if (-not [string]::IsNullOrWhiteSpace($Flavor)) {
  $flutterArgs += @("--flavor", $Flavor)
}
if (-not [string]::IsNullOrWhiteSpace($Target)) {
  $flutterArgs += @("-t", $Target)
}

# runtime defines consumidos por AppConfig (no solo Gradle).
$flutterArgs += @("--dart-define", "GOOGLE_MAPS_API_KEY=$resolvedKey")
if (-not [string]::IsNullOrWhiteSpace($resolvedBackend)) {
  $flutterArgs += @("--dart-define", "TEXI_BACKEND_BASE_URL=$resolvedBackend")
}

if ($Mode -eq "run") {
  Write-Host "Ejecutando: flutter run (dart-defines cargados)" -ForegroundColor Cyan
  & flutter run @flutterArgs
  exit $LASTEXITCODE
}

Write-Host "Ejecutando: flutter build apk (dart-defines cargados)" -ForegroundColor Cyan
& flutter build apk @flutterArgs
exit $LASTEXITCODE
