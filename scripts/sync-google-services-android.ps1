param(
  [ValidateSet("passenger", "driver")]
  [string]$App = "passenger",

  [switch]$ForceDevStub
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Solo dev stub (texi-prod). PROD nunca se genera aqui: descargar desde Firebase prodtexiappgm.
$devProjectNumber = "935442837361"
$devProjectId = "texi-prod"
$devStorageBucket = "texi-prod.firebasestorage.app"
$devApiKey = "AIzaSyBjgqer8v1_GaXV6zzwl5UQhTMV9GUBSTs"

if ($App -eq "driver") {
  $devPackage = "com.taxitexi.texi_driver_app.dev"
  $devAppId = "1:935442837361:android:c68446c652c01a37df50d0"
} else {
  $devPackage = "com.taxitexi.texi_passenger_app.dev"
  $devAppId = "1:935442837361:android:94a27f405c552edddf50d0"
}

function Test-IsOfficialGoogleServicesJson {
  param([string]$FilePath)

  if (-not (Test-Path $FilePath)) { return $false }
  try {
    $json = Get-Content $FilePath -Raw | ConvertFrom-Json
  } catch {
    return $false
  }

  $projectId = $json.project_info.project_id
  if ($projectId -eq "prodtexiappgm") { return $true }

  foreach ($c in @($json.client)) {
    if (@($c.oauth_client).Count -gt 0) { return $true }
  }
  return $false
}

function New-DevGoogleServicesStub {
  param(
    [string]$PackageName,
    [string]$MobileSdkAppId
  )

  $obj = @{
    project_info = @{
      project_number = $devProjectNumber
      project_id     = $devProjectId
      storage_bucket = $devStorageBucket
    }
    client = @(
      @{
        client_info = @{
          mobilesdk_app_id = $MobileSdkAppId
          android_client_info = @{
            package_name = $PackageName
          }
        }
        oauth_client = @()
        api_key      = @(@{ current_key = $devApiKey })
        services     = @{
          appinvite_service = @{
            other_platform_oauth_client = @()
          }
        }
      }
    )
    configuration_version = "1"
  }

  return ($obj | ConvertTo-Json -Depth 8)
}

$devDir = Join-Path $repoRoot "android\app\src\dev"
$prodPath = Join-Path $repoRoot "android\app\src\prod\google-services.json"
New-Item -ItemType Directory -Force -Path $devDir | Out-Null

$devPath = Join-Path $devDir "google-services.json"
if ((Test-IsOfficialGoogleServicesJson -FilePath $devPath) -and -not $ForceDevStub) {
  Write-Host "SKIP dev google-services.json (archivo oficial existente)." -ForegroundColor DarkGray
} else {
  New-DevGoogleServicesStub -PackageName $devPackage -MobileSdkAppId $devAppId |
    Set-Content -Path $devPath -Encoding UTF8
  Write-Host "OK stub dev google-services.json ($devPackage)" -ForegroundColor Green
}

if (Test-IsOfficialGoogleServicesJson -FilePath $prodPath) {
  Write-Host "OK prod google-services.json conservado (no sobrescribir)." -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "FAIL prod google-services.json ausente o es stub invalido." -ForegroundColor Red
  Write-Host "  Descarga desde Firebase prodtexiappgm -> app pasajero prod" -ForegroundColor Yellow
  Write-Host "  Guardar en: android/app/src/prod/google-services.json" -ForegroundColor Yellow
  Write-Host "  Luego: .\scripts\generate-firebase-options.ps1" -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

Write-Host "Sync completado (prod protegido; solo dev stub si aplica)." -ForegroundColor Green
