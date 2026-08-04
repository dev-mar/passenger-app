# Imprime checklist GCP Maps pasajero prod (prodtexiappgm). No modifica credenciales.
$ErrorActionPreference = "Stop"

$projectId = "prodtexiappgm"
$packageProd = "com.taxitexi.texi_passenger_app"

Write-Host ""
Write-Host "=== Maps pasajero prod - checklist GCP ===" -ForegroundColor Cyan
Write-Host "Proyecto canonico: $projectId (Firebase prod / Play Store)" -ForegroundColor White
Write-Host "NO usar: taxitexiapp-org / My First Project (legado)" -ForegroundColor Yellow
Write-Host ""

Write-Host "Enlaces directos:" -ForegroundColor Cyan
Write-Host "  Firebase settings: https://console.firebase.google.com/project/$projectId/settings/general"
Write-Host "  GCP Credentials:   https://console.cloud.google.com/apis/credentials?project=$projectId"
Write-Host "  GCP APIs enabled:  https://console.cloud.google.com/apis/dashboard?project=$projectId"
Write-Host "  GCP API Library:   https://console.cloud.google.com/apis/library?project=$projectId"
Write-Host ""

Write-Host "Paso 1 - Habilitar APIs en $projectId" -ForegroundColor Cyan
@(
  "Maps SDK for Android",
  "Geocoding API",
  "Directions API",
  "Places API legacy (obligatoria para lupa)"
) | ForEach-Object { Write-Host "  [ ] $_" }

Write-Host ""
Write-Host "Paso 2 - SHA-1 upload ($packageProd)" -ForegroundColor Cyan
Write-Host "  keytool -list -v -keystore D:\secrets\texi\texi-passenger-upload.jks -alias texi_passenger_upload"
Write-Host "  [ ] SHA-1 en Firebase app pasajero"
Write-Host "  [ ] SHA-1 en key Android SDK (abajo)"
Write-Host ""

Write-Host "Paso 3 - Key A: GOOGLE_MAPS_API_KEY (widget GoogleMap)" -ForegroundColor Cyan
Write-Host "  Nombre sugerido: Maps Android SDK prod - texi_passenger_app"
Write-Host "  Application restrictions: Android apps"
Write-Host "    Package: $packageProd"
Write-Host "    SHA-1: upload keystore"
Write-Host "  API restrictions: Maps SDK for Android (solo)"
Write-Host "  Archivo: texi_passenger_app/.env.prod"
Write-Host ""

Write-Host "Paso 4 - Key B: GOOGLE_MAPS_REST_API_KEY (lupa + rutas)" -ForegroundColor Cyan
Write-Host "  Nombre sugerido: Maps REST prod - texi_passenger_app"
Write-Host "  Application restrictions: None"
Write-Host "  API restrictions: Geocoding API + Directions API + Places API (legacy)"
Write-Host "  Archivo: texi_passenger_app/.env.prod"
Write-Host ""

Write-Host "Paso 5 - Verificar (Maps + Firebase + SMS)" -ForegroundColor Cyan
Write-Host "  .\scripts\generate-firebase-options.ps1"
Write-Host "  .\scripts\verify-passenger-prod-smoke-prereqs.ps1 -Environment prod"
Write-Host ""

Write-Host "Paso 6 - Build APK" -ForegroundColor Cyan
Write-Host "  .\scripts\run-with-maps-key.ps1 -Environment prod -Mode apk"
Write-Host ""
