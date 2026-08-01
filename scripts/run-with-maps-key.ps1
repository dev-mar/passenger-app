param(
  [ValidateSet("run", "apk", "appbundle")]
  [string]$Mode = "run",

  [string]$MapsApiKey,

  [ValidateSet("dev", "prod")]
  [string]$Environment = "dev",

  [string]$BackendBaseUrl,

  [bool]$PassengerSelfieCropEnabled = $true,

  [switch]$MultichannelAuth,

  [string]$Flavor,

  [string]$Target = "lib/main.dart"
)

$ErrorActionPreference = "Stop"

$DevBackendDefault = "https://api.dev.taxitexi.com"
$ProdBackendCanonical = "https://api-prodtx.taxitexi.com"

function Clear-InvalidProdBackendSessionEnv {
  if ([string]::IsNullOrWhiteSpace($env:TEXI_BACKEND_BASE_URL)) {
    return
  }
  try {
    $parsed = [Uri]$env:TEXI_BACKEND_BASE_URL.Trim()
    if (Test-InvalidProdBackendHost -HostName $parsed.Host) {
      Write-Host "Eliminando TEXI_BACKEND_BASE_URL de sesion (host invalido): $($env:TEXI_BACKEND_BASE_URL)" -ForegroundColor Yellow
      Remove-Item Env:TEXI_BACKEND_BASE_URL -ErrorAction SilentlyContinue
    }
  } catch {
    Remove-Item Env:TEXI_BACKEND_BASE_URL -ErrorAction SilentlyContinue
  }
}

function Test-InvalidProdBackendHost {
  param([string]$HostName)

  $h = $HostName.ToLower()
  if ($h -eq "api-prod.taxitexi.com") {
    return $true
  }
  return $h.StartsWith("api.prod")
}

function Assert-ValidProdBackendUrl {
  param(
    [string]$Url,
    [string]$Source = ""
  )

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return
  }

  $parsed = [Uri]$Url
  if (Test-InvalidProdBackendHost -HostName $parsed.Host) {
    Write-Host ""
    Write-Host "Host no valido para API backend en prod: $Url" -ForegroundColor Red
    if (-not [string]::IsNullOrWhiteSpace($Source)) {
      Write-Host "Origen: $Source" -ForegroundColor DarkYellow
    }
    Write-Host "Usa $ProdBackendCanonical" -ForegroundColor Yellow
    if ($Source -like '*sesion*') {
      Write-Host "Limpia la variable de sesion: Remove-Item Env:TEXI_BACKEND_BASE_URL" -ForegroundColor Yellow
    }
    exit 1
  }
}

function Get-LocalEnvFilePath {
  param([string]$AppEnvironment)

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  if ($AppEnvironment -eq "prod") {
    foreach ($name in @(".env.prod", ".env.prod.local")) {
      $candidate = Join-Path $repoRoot $name
      if (Test-Path $candidate) { return $candidate }
    }
    return Join-Path $repoRoot ".env.prod"
  }
  foreach ($name in @(".env.local", ".env")) {
    $candidate = Join-Path $repoRoot $name
    if (Test-Path $candidate) { return $candidate }
  }
  return Join-Path $repoRoot ".env.local"
}

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
  param(
    [string]$FromParam,
    [string]$AppEnvironment = "dev"
  )

  if (-not [string]::IsNullOrWhiteSpace($FromParam)) {
    return $FromParam.Trim()
  }

  if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_MAPS_API_KEY)) {
    return $env:GOOGLE_MAPS_API_KEY.Trim()
  }

  $envLocalPath = Get-LocalEnvFilePath -AppEnvironment $AppEnvironment
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "GOOGLE_MAPS_API_KEY"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim()
  }

  return ""
}

function Resolve-MultichannelAuth {
  param(
    [bool]$FromSwitch,
    [string]$AppEnvironment
  )

  if ($FromSwitch) {
    return $true
  }

  $raw = $env:TEXI_PASSENGER_MULTICHANNEL_AUTH
  if (-not [string]::IsNullOrWhiteSpace($raw)) {
    $normalized = $raw.Trim().ToLower()
    if ($normalized -in @("1", "true", "yes", "on")) {
      return $true
    }
  }

  $envLocalPath = Get-LocalEnvFilePath -AppEnvironment $AppEnvironment
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "TEXI_PASSENGER_MULTICHANNEL_AUTH"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    $normalized = $fromLocalFile.Trim().ToLower()
    if ($normalized -in @("1", "true", "yes", "on")) {
      return $true
    }
  }

  return $false
}

function Resolve-TurnstileSiteKey {
  param(
    [string]$AppEnvironment,
    [bool]$RequireForMultichannel
  )

  if (-not [string]::IsNullOrWhiteSpace($env:TURNSTILE_SITE_KEY)) {
    return $env:TURNSTILE_SITE_KEY.Trim()
  }

  $envLocalPath = Get-LocalEnvFilePath -AppEnvironment $AppEnvironment
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "TURNSTILE_SITE_KEY"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim()
  }

  if ($RequireForMultichannel) {
    Write-Host ""
    Write-Host "Falta TURNSTILE_SITE_KEY (requerida para step-up / multicanal)." -ForegroundColor Red
    Write-Host "Agrega TURNSTILE_SITE_KEY en .env.local (dev) o .env.prod (prod)." -ForegroundColor Yellow
    exit 1
  }

  return ""
}

function Resolve-GoogleOAuthServerClientId {
  param([string]$AppEnvironment)

  if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_OAUTH_SERVER_CLIENT_ID)) {
    return $env:GOOGLE_OAUTH_SERVER_CLIENT_ID.Trim()
  }

  $envLocalPath = Get-LocalEnvFilePath -AppEnvironment $AppEnvironment
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "GOOGLE_OAUTH_SERVER_CLIENT_ID"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim()
  }

  return ""
}

function Resolve-AppEnvironment {
  param([string]$FromParam)

  if (-not [string]::IsNullOrWhiteSpace($FromParam)) {
    return $FromParam.Trim().ToLower()
  }

  if (-not [string]::IsNullOrWhiteSpace($env:TEXI_APP_ENV)) {
    return $env:TEXI_APP_ENV.Trim().ToLower()
  }

  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $envLocalPath = Join-Path $repoRoot ".env.local"
  $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "TEXI_APP_ENV"
  if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
    return $fromLocalFile.Trim().ToLower()
  }

  return "dev"
}

function Get-BackendUrlFromProdEnvFiles {
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $value = ""
  foreach ($name in @(".env.prod", ".env.prod.local")) {
    $candidate = Join-Path $repoRoot $name
    $fromFile = Get-EnvValueFromLocalFile -FilePath $candidate -Key "TEXI_BACKEND_BASE_URL"
    if (-not [string]::IsNullOrWhiteSpace($fromFile)) {
      $value = $fromFile.Trim()
    }
  }
  return $value
}

function Resolve-BackendBaseUrl {
  param(
    [string]$FromParam,
    [string]$AppEnvironment
  )

  if (-not [string]::IsNullOrWhiteSpace($FromParam)) {
    return @{
      Url    = $FromParam.Trim()
      Source = "-BackendBaseUrl"
    }
  }

  if ($AppEnvironment -eq "prod") {
    $fromProdFiles = Get-BackendUrlFromProdEnvFiles
    if (-not [string]::IsNullOrWhiteSpace($fromProdFiles)) {
      return @{
        Url    = $fromProdFiles
        Source = ".env.prod / .env.prod.local"
      }
    }
  } else {
    $envLocalPath = Get-LocalEnvFilePath -AppEnvironment $AppEnvironment
    $fromLocalFile = Get-EnvValueFromLocalFile -FilePath $envLocalPath -Key "TEXI_BACKEND_BASE_URL"
    if (-not [string]::IsNullOrWhiteSpace($fromLocalFile)) {
      return @{
        Url    = $fromLocalFile.Trim()
        Source = (Split-Path $envLocalPath -Leaf)
      }
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($env:TEXI_BACKEND_BASE_URL)) {
    return @{
      Url    = $env:TEXI_BACKEND_BASE_URL.Trim()
      Source = '$env:TEXI_BACKEND_BASE_URL (sesion PowerShell)'
    }
  }

  if ($AppEnvironment -eq "dev") {
    return @{
      Url    = $DevBackendDefault
      Source = "default dev"
    }
  }

  return @{
    Url    = ""
    Source = ""
  }
}

$resolvedEnvironment = Resolve-AppEnvironment -FromParam $Environment
$resolvedMultichannelAuth = Resolve-MultichannelAuth -FromSwitch:$MultichannelAuth.IsPresent -AppEnvironment $resolvedEnvironment
$requireTurnstile = ($resolvedMultichannelAuth -or $resolvedEnvironment -eq "prod")
$resolvedTurnstileSiteKey = Resolve-TurnstileSiteKey -AppEnvironment $resolvedEnvironment -RequireForMultichannel:$requireTurnstile
$resolvedGoogleOAuthClientId = Resolve-GoogleOAuthServerClientId -AppEnvironment $resolvedEnvironment
Clear-InvalidProdBackendSessionEnv
$resolvedKey = Resolve-MapsKey -FromParam $MapsApiKey -AppEnvironment $resolvedEnvironment
$resolvedBackendInfo = Resolve-BackendBaseUrl -FromParam $BackendBaseUrl -AppEnvironment $resolvedEnvironment
$resolvedBackend = $resolvedBackendInfo.Url
$resolvedBackendSource = $resolvedBackendInfo.Source
$resolvedFlavor = $Flavor
if ([string]::IsNullOrWhiteSpace($resolvedFlavor)) {
  $resolvedFlavor = $resolvedEnvironment
}

if ([string]::IsNullOrWhiteSpace($resolvedKey)) {
  Write-Host ""
  Write-Host "Falta GOOGLE_MAPS_API_KEY." -ForegroundColor Red
  Write-Host "Opciones:" -ForegroundColor Yellow
  Write-Host "  1) Pasar por parametro: -MapsApiKey ""TU_KEY"""
  Write-Host "  2) Exportar variable: `$env:GOOGLE_MAPS_API_KEY=""TU_KEY"""
  Write-Host "  3) Dev: .env.local / .env | Prod: .env.prod (ver env.prod.example)"
  Write-Host ""
  Write-Host "Ejemplos:" -ForegroundColor Yellow
  Write-Host "  .\scripts\run-with-maps-key.ps1 -Mode run"
  Write-Host "  .\scripts\run-with-maps-key.ps1 -Mode apk"
  Write-Host "  .\scripts\run-with-maps-key.ps1 -Mode appbundle -Environment prod -BackendBaseUrl ""https://HOST_API_PROD"""
  exit 1
}

if ($resolvedEnvironment -eq "prod" -and [string]::IsNullOrWhiteSpace($resolvedBackend)) {
  Write-Host ""
  Write-Host "Build prod requiere TEXI_BACKEND_BASE_URL." -ForegroundColor Red
  Write-Host "Usa -BackendBaseUrl, `$env:TEXI_BACKEND_BASE_URL o .env.prod" -ForegroundColor Yellow
  exit 1
}

if ($resolvedEnvironment -eq "prod") {
  Assert-ValidProdBackendUrl -Url $resolvedBackend -Source $resolvedBackendSource
}

$env:GOOGLE_MAPS_API_KEY = $resolvedKey
$env:TEXI_APP_ENV = $resolvedEnvironment
$env:TEXI_BACKEND_BASE_URL = $resolvedBackend

$flutterArgs = @()
if (-not [string]::IsNullOrWhiteSpace($resolvedFlavor)) {
  $flutterArgs += @("--flavor", $resolvedFlavor)
}
if (-not [string]::IsNullOrWhiteSpace($Target)) {
  $flutterArgs += @("-t", $Target)
}

$flutterArgs += @("--dart-define", "TEXI_APP_ENV=$resolvedEnvironment")
$flutterArgs += @("--dart-define", "TEXI_BACKEND_BASE_URL=$resolvedBackend")
$flutterArgs += @("--dart-define", "GOOGLE_MAPS_API_KEY=$resolvedKey")
$flutterArgs += @("--dart-define", "PASSENGER_SELFIE_CROP_ENABLED=$($PassengerSelfieCropEnabled.ToString().ToLower())")
$flutterArgs += @("--dart-define", "SELFIE_CROP_ENABLED=$($PassengerSelfieCropEnabled.ToString().ToLower())")
$flutterArgs += @("--dart-define", "TEXI_PASSENGER_MULTICHANNEL_AUTH=$($resolvedMultichannelAuth.ToString().ToLower())")
if (-not [string]::IsNullOrWhiteSpace($resolvedTurnstileSiteKey)) {
  $flutterArgs += @("--dart-define", "TURNSTILE_SITE_KEY=$resolvedTurnstileSiteKey")
}
if (-not [string]::IsNullOrWhiteSpace($resolvedGoogleOAuthClientId)) {
  $flutterArgs += @("--dart-define", "GOOGLE_OAUTH_SERVER_CLIENT_ID=$resolvedGoogleOAuthClientId")
}

$multichannelLabel = if ($resolvedMultichannelAuth) { "on (WA inbound QA)" } else { "off" }
$turnstileLabel = if ([string]::IsNullOrWhiteSpace($resolvedTurnstileSiteKey)) { "off" } else { "on" }
$googleLabel = if ([string]::IsNullOrWhiteSpace($resolvedGoogleOAuthClientId)) { "off" } else { "on" }
Write-Host "Entorno: $resolvedEnvironment | Flavor: $resolvedFlavor | Backend: $resolvedBackend | Multicanal: $multichannelLabel | Turnstile: $turnstileLabel | Google: $googleLabel" -ForegroundColor DarkGray

if ($Mode -eq "run") {
  Write-Host "Ejecutando: flutter run (dart-defines cargados)" -ForegroundColor Cyan
  & flutter run @flutterArgs
  exit $LASTEXITCODE
}

$buildCmd = if ($Mode -eq "appbundle") { "appbundle" } else { "apk" }
Write-Host "Ejecutando: flutter build $buildCmd (dart-defines cargados)" -ForegroundColor Cyan
$syncGoogleServices = Join-Path $PSScriptRoot "sync-google-services-android.ps1"
if (Test-Path $syncGoogleServices) {
  & $syncGoogleServices -App passenger
}
$prepareScript = Join-Path $PSScriptRoot "prepare-android-build.ps1"
if (Test-Path $prepareScript) {
  # Igual que conductor: detener daemons antes del build (evita locks corruptos).
  # No compilar pasajero y conductor en paralelo: comparten daemon/caché Gradle global.
  & $prepareScript
}
& flutter build $buildCmd @flutterArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($resolvedEnvironment -eq "prod" -and $Mode -eq "apk") {
  $apkPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "build\app\outputs\flutter-apk\app-$resolvedFlavor-release.apk"
  $verifyScript = Join-Path $PSScriptRoot "verify-apk-backend-url.ps1"
  if ((Test-Path $apkPath) -and (Test-Path $verifyScript)) {
    & $verifyScript -ApkPath $apkPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
}

exit $LASTEXITCODE
