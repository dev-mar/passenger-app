param(
  [ValidateSet("passenger", "driver")]
  [string]$App = "passenger"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$projectNumber = "935442837361"
$projectId = "texi-prod"
$storageBucket = "texi-prod.firebasestorage.app"
$apiKey = "AIzaSyBjgqer8v1_GaXV6zzwl5UQhTMV9GUBSTs"

if ($App -eq "driver") {
  $prodPackage = "com.taxitexi.texi_driver_app"
  $prodAppId = "1:935442837361:android:c68446c652c01a37df50d0"
  $devPackage = "com.taxitexi.texi_driver_app.dev"
  $devAppId = $prodAppId
} else {
  $prodPackage = "com.taxitexi.texi_passenger_app"
  $prodAppId = "1:935442837361:android:94a27f405c552edddf50d0"
  $devPackage = "com.taxitexi.texi_passenger_app.dev"
  $devAppId = $prodAppId
}

function New-GoogleServicesJson {
  param(
    [string]$PackageName,
    [string]$MobileSdkAppId
  )

  $obj = @{
    project_info = @{
      project_number = $projectNumber
      project_id = $projectId
      storage_bucket = $storageBucket
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
        api_key = @(
          @{ current_key = $apiKey }
        )
        services = @{
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
$prodDir = Join-Path $repoRoot "android\app\src\prod"
New-Item -ItemType Directory -Force -Path $devDir | Out-Null
New-Item -ItemType Directory -Force -Path $prodDir | Out-Null

New-GoogleServicesJson -PackageName $devPackage -MobileSdkAppId $devAppId |
  Set-Content -Path (Join-Path $devDir "google-services.json") -Encoding UTF8

New-GoogleServicesJson -PackageName $prodPackage -MobileSdkAppId $prodAppId |
  Set-Content -Path (Join-Path $prodDir "google-services.json") -Encoding UTF8

Write-Host "google-services.json generado para dev ($devPackage) y prod ($prodPackage)." -ForegroundColor Green
Write-Host "Nota: registra la app .dev en Firebase Console y reemplaza mobilesdk_app_id dev cuando FCM dev esté listo." -ForegroundColor Yellow
