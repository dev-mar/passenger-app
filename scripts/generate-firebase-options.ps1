# Genera lib/firebase_options.dart desde google-services.json (dev + prod).
# No imprime API keys en consola.
param(
  [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Read-FirebaseClientBlock {
  param(
    [string]$JsonPath,
    [string]$ExpectedPackage
  )

  if (-not (Test-Path $JsonPath)) {
    throw "No existe: $JsonPath"
  }

  $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
  $match = $null
  foreach ($c in @($json.client)) {
    if ($c.client_info.android_client_info.package_name -eq $ExpectedPackage) {
      $match = $c
      break
    }
  }
  if ($null -eq $match) {
    throw "No hay bloque $ExpectedPackage en $JsonPath"
  }

  return @{
    ApiKey            = $match.api_key[0].current_key
    AppId             = $match.client_info.mobilesdk_app_id
    MessagingSenderId = $json.project_info.project_number
    ProjectId         = $json.project_info.project_id
    StorageBucket     = $json.project_info.storage_bucket
    Package           = $ExpectedPackage
    Path              = $JsonPath
  }
}

$dev = Read-FirebaseClientBlock `
  -JsonPath (Join-Path $repoRoot "android\app\src\dev\google-services.json") `
  -ExpectedPackage "com.taxitexi.texi_passenger_app.dev"

$prod = Read-FirebaseClientBlock `
  -JsonPath (Join-Path $repoRoot "android\app\src\prod\google-services.json") `
  -ExpectedPackage "com.taxitexi.texi_passenger_app"

if ($CheckOnly) {
  Write-Host "OK dev  project=$($dev.ProjectId) appId=$($dev.AppId)" -ForegroundColor Green
  Write-Host "OK prod project=$($prod.ProjectId) appId=$($prod.AppId)" -ForegroundColor Green
  if ($prod.ProjectId -ne "prodtexiappgm") {
    Write-Host "FAIL prod google-services.json apunta a $($prod.ProjectId), se esperaba prodtexiappgm" -ForegroundColor Red
    Write-Host "     Probable causa: sync-google-services-android.ps1 sobrescribio el archivo." -ForegroundColor Yellow
    Write-Host "     Restaurar JSON desde Firebase Console y NO usar stub prod." -ForegroundColor Yellow
    exit 1
  }
  $prodJsonPath = Join-Path $repoRoot "android\app\src\prod\google-services.json"
  $prodJson = Get-Content $prodJsonPath -Raw | ConvertFrom-Json
  if ($prodJson.project_info.project_id -ne "prodtexiappgm") {
    Write-Host "FAIL prod google-services.json project_id=$($prodJson.project_info.project_id)" -ForegroundColor Red
    exit 1
  }
  $passenger = $null
  foreach ($c in @($prodJson.client)) {
    if ($c.client_info.android_client_info.package_name -eq "com.taxitexi.texi_passenger_app") {
      $passenger = $c
      break
    }
  }
  if ($null -eq $passenger) {
    Write-Host "FAIL prod google-services.json sin bloque com.taxitexi.texi_passenger_app" -ForegroundColor Red
    exit 1
  }
  if (@($prodJson.client).Count -gt 1) {
    Write-Host "OK prod JSON multi-app (conductor+pasajero); se usa bloque pasajero por package." -ForegroundColor DarkGray
  }
  if (@($passenger.oauth_client).Count -eq 0) {
    Write-Host "FAIL prod google-services.json sin oauth_client para pasajero" -ForegroundColor Red
    Write-Host "     Descargar de nuevo desde Firebase prodtexiappgm." -ForegroundColor Yellow
    exit 1
  }
  exit 0
}

$outPath = Join-Path $repoRoot "lib\firebase_options.dart"
$content = @"
// Generado por scripts/generate-firebase-options.ps1
// Fuentes: android/app/src/{dev|prod}/google-services.json
//
// Dev:  $($dev.ProjectId) - $($dev.Package)
// Prod: $($prod.ProjectId) - $($prod.Package)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/passenger_app_environment.dart';

/// Configuracion Firebase — app pasajero.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions: web no configurado para esta app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PassengerAppEnvironment.isProd ? androidProd : androidDev;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions: anade GoogleService-Info.plist y flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: plataforma no soportada.',
        );
    }
  }

  static const FirebaseOptions androidDev = FirebaseOptions(
    apiKey: '$($dev.ApiKey)',
    appId: '$($dev.AppId)',
    messagingSenderId: '$($dev.MessagingSenderId)',
    projectId: '$($dev.ProjectId)',
    storageBucket: '$($dev.StorageBucket)',
  );

  static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: '$($prod.ApiKey)',
    appId: '$($prod.AppId)',
    messagingSenderId: '$($prod.MessagingSenderId)',
    projectId: '$($prod.ProjectId)',
    storageBucket: '$($prod.StorageBucket)',
  );
}
"@

Set-Content -Path $outPath -Value $content -Encoding UTF8
Write-Host "OK Generado $outPath" -ForegroundColor Green
Write-Host "  dev  -> $($dev.ProjectId) / $($dev.AppId)" -ForegroundColor DarkGray
Write-Host "  prod -> $($prod.ProjectId) / $($prod.AppId)" -ForegroundColor DarkGray
