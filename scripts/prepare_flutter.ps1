$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\app"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter bulunamadı. Flutter 3.47+ kurun."
}

flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
dart run flutter_launcher_icons

Write-Host "Hazır. Örnek:"
Write-Host "flutter run --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr"
