# Verifica que un APK prod embeba el host canónico de API y no hosts legacy de backend.
# Nota: api.prod.taxitexi.com puede aparecer legítimamente como origen virtual Turnstile (WebView step-up).
param(
  [Parameter(Mandatory = $true)]
  [string]$ApkPath,

  [string]$ExpectedHost = "api-prodtx.taxitexi.com"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ApkPath)) {
  Write-Host "APK no encontrado: $ApkPath" -ForegroundColor Red
  exit 1
}

# Solo hosts que indicarían backend API mal compilado (no Turnstile WebView).
$forbiddenBackendPatterns = @(
  "api.prodtx.taxitexi.com"
)

$turnstileOriginHost = "api.prod.taxitexi.com"

$tmp = Join-Path $env:TEMP ("apk-verify-{0}" -f [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Copy-Item $ApkPath (Join-Path $tmp "app.zip")
  Expand-Archive -Path (Join-Path $tmp "app.zip") -DestinationPath (Join-Path $tmp "extract") -Force
  $libapp = Get-ChildItem -Path (Join-Path $tmp "extract") -Recurse -Filter "libapp.so" | Select-Object -First 1
  if (-not $libapp) {
    Write-Host "No se encontro libapp.so en el APK." -ForegroundColor Red
    exit 1
  }

  $bytes = [System.IO.File]::ReadAllBytes($libapp.FullName)
  $text = [System.Text.Encoding]::UTF8.GetString($bytes)

  foreach ($bad in $forbiddenBackendPatterns) {
    if ($text.Contains($bad)) {
      Write-Host "Host legacy de backend encontrado en APK: $bad" -ForegroundColor Red
      Write-Host "Recompila con .env.prod y sin `$env:TEXI_BACKEND_BASE_URL legacy." -ForegroundColor Yellow
      exit 1
    }
  }

  if (-not $text.Contains($ExpectedHost)) {
    Write-Host "Advertencia: no se encontro $ExpectedHost en libapp.so (revisar dart-define)." -ForegroundColor Yellow
    exit 1
  }

  if ($text.Contains($turnstileOriginHost)) {
    Write-Host "APK OK: $ExpectedHost (API) + $turnstileOriginHost (Turnstile WebView)." -ForegroundColor Green
  } else {
    Write-Host "APK OK: $ExpectedHost presente; sin hosts legacy de backend." -ForegroundColor Green
  }
  exit 0
}
finally {
  if (Test-Path $tmp) {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
