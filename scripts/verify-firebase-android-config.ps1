param(
  [ValidateSet("dev", "prod", "all")]
  [string]$Flavor = "all"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$expectedPackages = @{
  prod = "com.taxitexi.texi_passenger_app"
  dev  = "com.taxitexi.texi_passenger_app.dev"
}

$expectedProdProjectId = "prodtexiappgm"
$expectedProdPassengerAppId = "1:464855616265:android:112ed9f31d26c508c6a1d8"

$targets = @()
if ($Flavor -eq "all") { $targets = @("dev", "prod") } else { $targets = @($Flavor) }

$failed = 0
foreach ($f in $targets) {
  $path = Join-Path $repoRoot "android\app\src\$f\google-services.json"
  $expectedPkg = $expectedPackages[$f]
  Write-Host "=== google-services.json ($f) ===" -ForegroundColor Cyan
  if (-not (Test-Path $path)) {
    Write-Host "FAIL No existe: $path" -ForegroundColor Red
    $failed++
    continue
  }

  $json = Get-Content $path -Raw | ConvertFrom-Json
  $projectId = $json.project_info.project_id
  Write-Host "project_id: $projectId"

  if ($f -eq "prod" -and $projectId -ne $expectedProdProjectId) {
    Write-Host "FAIL prod debe usar project_id=$expectedProdProjectId (en disco: $projectId)" -ForegroundColor Red
    Write-Host "     Si ves texi-prod, el stub de sync sobrescribio el archivo oficial." -ForegroundColor Yellow
    Write-Host "     Vuelve a pegar el JSON descargado de Firebase prodtexiappgm." -ForegroundColor Yellow
    $failed++
  }

  $clients = @($json.client)
  Write-Host "client blocks in file: $($clients.Count)"
  if ($f -eq "prod" -and $clients.Count -gt 1) {
    Write-Host "OK Varios paquetes en el mismo JSON (conductor+pasajero) es normal." -ForegroundColor DarkGray
    Write-Host "   Gradle/Firebase eligen el bloque cuyo package_name coincide con applicationId del flavor." -ForegroundColor DarkGray
  }

  $match = $null
  foreach ($c in $clients) {
    $pkg = $c.client_info.android_client_info.package_name
    Write-Host "  - $pkg (oauth: $(@($c.oauth_client).Count))"
    if ($pkg -eq $expectedPkg) { $match = $c }
  }

  if ($null -eq $match) {
    Write-Host "FAIL No hay bloque para package esperado: $expectedPkg" -ForegroundColor Red
    $failed++
    continue
  }

  $appId = $match.client_info.mobilesdk_app_id
  $oauthCount = @($match.oauth_client).Count
  Write-Host "match pasajero: $expectedPkg app_id=$appId"

  if ($f -eq "prod" -and $appId -ne $expectedProdPassengerAppId) {
    Write-Host "WARN app_id pasajero distinto al prod canonico ($expectedProdPassengerAppId)" -ForegroundColor Yellow
  }

  if ($oauthCount -eq 0) {
    Write-Host "FAIL oauth_client vacio en bloque pasajero (JSON stub o descarga incompleta)" -ForegroundColor Red
    $failed++
  } else {
    Write-Host "OK oauth_client presente para pasajero ($oauthCount entradas)" -ForegroundColor Green
  }
}

if ($failed -gt 0) {
  Write-Host ""
  Write-Host "Checklist Firebase (prodtexiappgm):" -ForegroundColor Yellow
  Write-Host "  1. Project settings -> app com.taxitexi.texi_passenger_app -> Download google-services.json"
  Write-Host "  2. Guardar en: android/app/src/prod/google-services.json (puede incluir conductor+pasajero)"
  Write-Host "  3. Authentication -> Phone -> Enable + SHA-1 upload en la app pasajero"
  Write-Host "  4. .\scripts\generate-firebase-options.ps1"
  Write-Host "  NO ejecutar sync stub sobre prod (scripts/sync-google-services-android.ps1 ya protege prod)."
  exit 1
}

Write-Host ""
Write-Host "OK Config Firebase Android verificada para pasajero." -ForegroundColor Green
exit 0
