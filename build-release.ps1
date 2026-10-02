# =============================================================================
#  Compile les versions publiables de l'application Sports SM et les copie dans
#  2sm-laravel\public\downloads\ (les boutons de la page d'accueil s'activent).
#     powershell -ExecutionPolicy Bypass -File build-release.ps1 [-Api https://2sm.fun/api] [-Android] [-Windows]
#  Sans -Android ni -Windows : les deux.
# =============================================================================
param(
  [string]$Api = 'https://2sm.fun/api',
  [switch]$Android,
  [switch]$Windows
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$downloads = Join-Path $PSScriptRoot '..\2sm-laravel\public\downloads'
New-Item -ItemType Directory -Force $downloads | Out-Null
if (-not $Android -and -not $Windows) { $Android = $true; $Windows = $true }

# Liens temporaires vers les plugins laissés par une compilation précédente : Flutter
# refuse de les recréer sous Windows (« Cannot create link … errno = 183 »).
foreach ($p in 'windows', 'linux', 'macos') {
  $links = Join-Path $PSScriptRoot "$p/flutter/ephemeral/.plugin_symlinks"
  if (Test-Path $links) { cmd /c rmdir /s /q "`"$links`"" }
}

flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a échoué' }

if ($Android) {
  Write-Host "→ Android (APK, API : $Api)"
  flutter build apk --release --dart-define=API_BASE_URL=$Api
  if ($LASTEXITCODE -ne 0) { throw 'La compilation Android a échoué' }
  Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $downloads '2sm-android.apk') -Force
  Write-Host '  ✓ public\downloads\2sm-android.apk'
}

if ($Windows) {
  Write-Host "→ Windows (API : $Api)"
  flutter build windows --release --dart-define=API_BASE_URL=$Api
  if ($LASTEXITCODE -ne 0) { throw 'La compilation Windows a échoué' }
  $zip = Join-Path $downloads '2sm-windows.zip'
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath $zip
  Write-Host '  ✓ public\downloads\2sm-windows.zip'
}

Write-Host 'Terminé. Téléversez le dossier public\downloads sur le serveur (ou refaites l''archive de déploiement).'
