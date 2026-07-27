param(
  # Solo quita locks; no ejecuta gradlew --stop ni mata procesos Java (uso antes de flutter build).
  [switch]$LocksOnly
)
# Libera locks Gradle (proyecto + cachÃ© global en %USERPROFILE%\.gradle) antes de flutter build apk.
# Uso: .\scripts\prepare-android-build.ps1 [-LocksOnly]

$ErrorActionPreference = "Stop"
$androidDir = Join-Path $PSScriptRoot "..\android" | Resolve-Path
$projectLock = Join-Path $androidDir ".gradle\8.14\executionHistory\executionHistory.lock"
$globalJournalLock = Join-Path $env:USERPROFILE ".gradle\caches\journal-1\journal-1.lock"

function Resolve-JavaHomeForGradle {
  if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    return $env:JAVA_HOME
  }
  $candidates = @(
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr",
    "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr"
  )
  foreach ($path in $candidates) {
    if (Test-Path "$path\bin\java.exe") { return $path }
  }
  return $null
}

function Stop-GradleDaemonJavaProcesses {
  $gradleJava = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'GradleDaemon|org\.gradle\.launcher' }
  foreach ($proc in $gradleJava) {
    Write-Host "  Cerrando Gradle daemon java PID $($proc.ProcessId)..." -ForegroundColor Yellow
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
  }
}

function Remove-LockFileIfPresent([string]$path) {
  if (Test-Path $path) {
    Remove-Item $path -Force -ErrorAction SilentlyContinue
    Write-Host "Lock eliminado: $path" -ForegroundColor Green
  }
}

$javaHome = Resolve-JavaHomeForGradle
if ($javaHome) {
  $env:JAVA_HOME = $javaHome
  $env:PATH = "$javaHome\bin;$env:PATH"
  Write-Host "JAVA_HOME=$javaHome" -ForegroundColor DarkGray
}

if (-not $LocksOnly) {
  Write-Host "Deteniendo daemons Gradle..." -ForegroundColor Cyan
  $gradlew = Join-Path $androidDir "gradlew.bat"
  if ((Test-Path $gradlew) -and $javaHome) {
    & $gradlew -p $androidDir --stop 2>$null
  }

  Stop-GradleDaemonJavaProcesses
  Start-Sleep -Seconds 2
} else {
  Write-Host "Modo LocksOnly: no se detienen daemons Gradle." -ForegroundColor DarkGray
}
Remove-LockFileIfPresent $projectLock
Remove-LockFileIfPresent $globalJournalLock

Write-Host "Listo. Ejecuta el build (un solo proyecto a la vez)." -ForegroundColor Green
