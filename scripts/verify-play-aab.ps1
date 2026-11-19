# Verifica el AAB de produccion antes de subirlo a Play Console.
# Con Meta desactivado: el manifiesto fusionado NO debe incluir
# com.google.android.gms.permission.AD_ID (declaracion Play = No -> sin bloqueo).
#
# Uso:
#   .\scripts\verify-play-aab.ps1
#   .\scripts\verify-play-aab.ps1 -AabPath "D:\ruta\app-prod-release.aab"

param(
  [string]$AabPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($AabPath)) {
  $AabPath = Join-Path $repoRoot "build\app\outputs\bundle\prodRelease\app-prod-release.aab"
}

if (-not (Test-Path $AabPath)) {
  Write-Host "FAIL: no existe el AAB: $AabPath" -ForegroundColor Red
  Write-Host "Genera primero: .\scripts\build-channel.ps1 -Channel prod -Mode appbundle" -ForegroundColor Yellow
  exit 1
}

$adIdPermission = "com.google.android.gms.permission.AD_ID"

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($AabPath)
try {
  $entry = $zip.GetEntry("base/manifest/AndroidManifest.xml")
  if ($null -eq $entry) {
    Write-Host "FAIL: el AAB no contiene base/manifest/AndroidManifest.xml" -ForegroundColor Red
    exit 1
  }
  $reader = New-Object System.IO.StreamReader($entry.Open())
  try {
    $raw = $reader.ReadToEnd()
  } finally {
    $reader.Dispose()
  }
} finally {
  $zip.Dispose()
}

$item = Get-Item -LiteralPath $AabPath

Write-Host "AAB: $($item.FullName)" -ForegroundColor Cyan
Write-Host "Tamano MB: $([math]::Round($item.Length / 1MB, 2))" -ForegroundColor DarkGray
$hashSha256 = (Get-FileHash -LiteralPath $AabPath -Algorithm SHA256).Hash
Write-Host "SHA256: $hashSha256" -ForegroundColor DarkGray
Write-Host "Sube este archivo exacto a Play (renombrar no cambia el hash)." -ForegroundColor DarkGray

if ($raw -match [regex]::Escape($adIdPermission)) {
  Write-Host "FAIL: el manifiesto base todavia incluye $adIdPermission (declara No en Play o quita dependencias que lo fusionen)." -ForegroundColor Red
  exit 1
}

Write-Host "OK: manifiesto base sin $adIdPermission (coherente con declaracion No)" -ForegroundColor Green

# Manifest binario del AAB a veces no expone versionCode como ASCII; refuerzo con merge Gradle
$xml = ""
$packaged = Join-Path $repoRoot "build\app\intermediates\packaged_manifests\prodRelease\processProdReleaseManifestForPackage\AndroidManifest.xml"
if (Test-Path $packaged) {
  $xml = Get-Content -LiteralPath $packaged -Raw -ErrorAction SilentlyContinue
  if ($xml -match 'android:versionCode="(\d+)"') {
    Write-Host "versionCode (Gradle packaged): $($Matches[1])" -ForegroundColor DarkGray
  }
  if ($xml -match 'android:versionName="([^"]+)"') {
    Write-Host "versionName (Gradle packaged): $($Matches[1])" -ForegroundColor DarkGray
  }
} elseif ($raw -match 'versionCode="(\d+)"') {
  Write-Host "versionCode detectado en manifest del AAB: $($Matches[1])" -ForegroundColor DarkGray
}

$expectedPackage = "com.taxitexi.texi_passenger_app"
if (-not [string]::IsNullOrWhiteSpace($xml)) {
  if ($xml -notmatch [regex]::Escape($expectedPackage)) {
    Write-Host "WARN: no se encontro package $expectedPackage en manifest empaquetado (revisa applicationId)." -ForegroundColor Yellow
  } else {
    Write-Host "OK: package $expectedPackage presente en manifest" -ForegroundColor DarkGreen
  }
}

exit 0
