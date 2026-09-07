@echo off
setlocal
cd /d "%~dp0\.."
where flutter >nul 2>nul || (echo Flutter SDK bulunamadi. & exit /b 1)
if not exist android\gradlew rmdir /S /Q android 2>nul
if not exist ios\Runner.xcodeproj\project.pbxproj rmdir /S /Q ios 2>nul
flutter create --platforms=android,ios --org com.sinematch --project-name sinematch . || exit /b 1
python scripts\configure_platforms.py || py scripts\configure_platforms.py || exit /b 1
flutter pub get || exit /b 1
dart run flutter_launcher_icons || exit /b 1
flutter clean
flutter pub get
if "%~1"=="" (
  flutter build apk --release
) else (
  flutter build apk --release --dart-define=SINEMATCH_API_URL=%~1
)
if errorlevel 1 exit /b 1
if not exist dist mkdir dist
copy /Y build\app\outputs\flutter-apk\app-release.apk dist\SineMatch-v1.0.0.apk >nul
echo APK: %CD%\dist\SineMatch-v1.0.0.apk
