@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
color 0D
title SineMatch - Tek Tik APK Kurulum ve Build

set "APP_NAME=SineMatch"
set "APP_VERSION=1.0.0"
set "TOOLS_DIR=%USERPROFILE%\sinematch_tools"
set "FLUTTER_ROOT=%TOOLS_DIR%\flutter"
set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
set "ANDROID_HOME=%ANDROID_SDK_ROOT%"
set "CMDLINE_URL=https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip"
set "CMDLINE_ZIP=%TEMP%\sinematch_android_cmdline.zip"
set "CMDLINE_TMP=%TEMP%\sinematch_android_cmdline"
set "PROJECT_DIR=%~dp0"

cls
echo ================================================================
echo              SINEMATCH - TEK TIK APK BUILDER
echo ================================================================
echo.
echo Bu arac:
echo   - Git ve Java 17'yi kontrol eder / kurar
echo   - Guncel Flutter Stable SDK'yi indirir
echo   - Android SDK Command-line Tools'u kurar
echo   - Android lisanslarini kabul eder
echo   - SineMatch launcher ikonlarini uygular
echo   - Release APK uretir ve Masaustu'ne kopyalar
echo.
echo Internet baglantisi ve yaklasik 8-12 GB bos alan gerekir.
echo.

:: Admin yetkisi: winget kurulumlarinda sorun yasamamasi icin kendini yukseltir.
net session >nul 2>&1
if errorlevel 1 (
  echo Yonetici izni isteniyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: Proje konumunu bul.
if exist "%PROJECT_DIR%pubspec.yaml" goto project_found
if exist "%PROJECT_DIR%sinematch_pro\app\pubspec.yaml" (
  set "PROJECT_DIR=%PROJECT_DIR%sinematch_pro\app\"
  goto project_found
)

:: BAT dosyasi ZIP'in yanindaysa projeyi otomatik ac.
if exist "%~dp0SineMatch_Flutter_BuildReady_v1.0.0.zip" (
  echo [1/9] SineMatch proje ZIP'i aciliyor...
  if exist "%~dp0_SineMatchBuild" rmdir /S /Q "%~dp0_SineMatchBuild"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '%~dp0SineMatch_Flutter_BuildReady_v1.0.0.zip' -DestinationPath '%~dp0_SineMatchBuild' -Force"
  if errorlevel 1 goto fail
  if exist "%~dp0_SineMatchBuild\sinematch_pro\app\pubspec.yaml" (
    set "PROJECT_DIR=%~dp0_SineMatchBuild\sinematch_pro\app\"
    goto project_found
  )
)

echo [HATA] pubspec.yaml bulunamadi.
echo Bu BAT'i SineMatch Flutter projesindeki pubspec.yaml ile ayni klasore koy,
echo veya SineMatch_Flutter_BuildReady_v1.0.0.zip dosyasinin yanina koy.
goto fail

:project_found
echo [OK] Proje: %PROJECT_DIR%

:: winget kontrolu
where winget >nul 2>&1
if errorlevel 1 (
  echo.
  echo [HATA] Windows Package Manager ^(winget^) bulunamadi.
  echo Windows 10/11 App Installer'i Microsoft Store'dan guncelleyip tekrar calistir.
  start ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1
  goto fail
)

:: Git
where git >nul 2>&1
if errorlevel 1 (
  echo [2/9] Git kuruluyor...
  winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements --silent
  if errorlevel 1 goto fail
)
set "PATH=C:\Program Files\Git\cmd;%PATH%"
where git >nul 2>&1
if errorlevel 1 goto fail

echo [OK] Git hazir.

:: Java 17 - Android Gradle icin sabit ve guvenilir hedef.
echo [3/9] Java 17 kontrol ediliyor...
winget install --id EclipseAdoptium.Temurin.17.JDK -e --source winget --accept-package-agreements --accept-source-agreements --silent >nul 2>&1

set "JAVA_HOME="
for /f "usebackq delims=" %%J in (`powershell -NoProfile -Command "$d=Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue ^| Where-Object {$_.Name -like 'jdk-17*'} ^| Sort-Object LastWriteTime -Descending ^| Select-Object -First 1; if($d){$d.FullName}"`) do set "JAVA_HOME=%%J"
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"
where java >nul 2>&1
if errorlevel 1 (
  echo [HATA] Java kurulumu bulunamadi.
  goto fail
)
echo [OK] Java hazir: %JAVA_HOME%

:: Flutter Stable - resmi releases JSON'dan guncel stable arsivi bulur.
if not exist "%FLUTTER_ROOT%\bin\flutter.bat" (
  echo [4/9] Guncel Flutter Stable indiriliyor...
  if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
  set "FLUTTER_ZIP=%TEMP%\sinematch_flutter_stable.zip"
  if exist "!FLUTTER_ZIP!" del /Q "!FLUTTER_ZIP!"
  if exist "%FLUTTER_ROOT%" rmdir /S /Q "%FLUTTER_ROOT%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $r=Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'; $h=$r.current_release.stable; $rel=$r.releases ^| Where-Object {$_.hash -eq $h} ^| Select-Object -First 1; if(-not $rel){throw 'Flutter stable surumu bulunamadi'}; $url='https://storage.googleapis.com/flutter_infra_release/releases/'+$rel.archive; Write-Host ('Flutter '+$rel.version+' indiriliyor...'); Invoke-WebRequest -Uri $url -OutFile '!FLUTTER_ZIP!'; Expand-Archive -LiteralPath '!FLUTTER_ZIP!' -DestinationPath '%TOOLS_DIR%' -Force"
  if errorlevel 1 goto fail
  del /Q "!FLUTTER_ZIP!" >nul 2>&1
)
set "PATH=%FLUTTER_ROOT%\bin;%PATH%"
call "%FLUTTER_ROOT%\bin\flutter.bat" --version
if errorlevel 1 goto fail

echo [OK] Flutter hazir.

:: Android Command-line Tools
set "SDKMANAGER=%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat"
if not exist "%SDKMANAGER%" (
  echo [5/9] Android SDK Command-line Tools indiriliyor...
  if not exist "%ANDROID_SDK_ROOT%" mkdir "%ANDROID_SDK_ROOT%"
  if exist "%CMDLINE_ZIP%" del /Q "%CMDLINE_ZIP%"
  if exist "%CMDLINE_TMP%" rmdir /S /Q "%CMDLINE_TMP%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%CMDLINE_URL%' -OutFile '%CMDLINE_ZIP%'; Expand-Archive -LiteralPath '%CMDLINE_ZIP%' -DestinationPath '%CMDLINE_TMP%' -Force"
  if errorlevel 1 goto fail
  if not exist "%ANDROID_SDK_ROOT%\cmdline-tools\latest" mkdir "%ANDROID_SDK_ROOT%\cmdline-tools\latest"
  xcopy "%CMDLINE_TMP%\cmdline-tools\*" "%ANDROID_SDK_ROOT%\cmdline-tools\latest\" /E /I /H /Y >nul
  if errorlevel 1 goto fail
  del /Q "%CMDLINE_ZIP%" >nul 2>&1
  rmdir /S /Q "%CMDLINE_TMP%" >nul 2>&1
)
if not exist "%SDKMANAGER%" goto fail
set "PATH=%ANDROID_SDK_ROOT%\platform-tools;%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin;%PATH%"

echo [6/9] Android SDK paketleri ve lisanslar hazirlaniyor...
(for /L %%L in (1,1,100) do @echo y) | call "%SDKMANAGER%" --sdk_root="%ANDROID_SDK_ROOT%" --licenses >nul 2>&1
call "%SDKMANAGER%" --sdk_root="%ANDROID_SDK_ROOT%" "platform-tools" "platforms;android-35" "platforms;android-36" "build-tools;35.0.0" "build-tools;36.0.0"
if errorlevel 1 goto fail
(for /L %%L in (1,1,100) do @echo y) | call "%SDKMANAGER%" --sdk_root="%ANDROID_SDK_ROOT%" --licenses >nul 2>&1

call "%FLUTTER_ROOT%\bin\flutter.bat" config --android-sdk "%ANDROID_SDK_ROOT%" >nul
call "%FLUTTER_ROOT%\bin\flutter.bat" precache --android
if errorlevel 1 goto fail

:: Flutter Android platformunu eksiksiz olustur.
echo [7/9] SineMatch Android platformu hazirlaniyor...
cd /d "%PROJECT_DIR%"
if not exist "pubspec.yaml" goto fail
if not exist "android\gradlew.bat" (
  if exist "android" rmdir /S /Q "android"
  call "%FLUTTER_ROOT%\bin\flutter.bat" create --platforms=android,ios --org com.sinematch --project-name sinematch .
  if errorlevel 1 goto fail
)

:: Android package id, uygulama adi, internet izni ve minSdk ayarlari.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $p='android/app/build.gradle.kts'; $s=Get-Content -Raw $p; $s=$s -replace 'namespace\s*=\s*\"[^\"]+\"','namespace = \"com.sinematch.app\"'; $s=$s -replace 'applicationId\s*=\s*\"[^\"]+\"','applicationId = \"com.sinematch.app\"'; $s=$s -replace 'minSdk\s*=\s*flutter\.minSdkVersion','minSdk = 24'; Set-Content -LiteralPath $p -Value $s -Encoding UTF8"
if errorlevel 1 goto fail

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $p='android/app/src/main/AndroidManifest.xml'; $s=Get-Content -Raw $p; if($s -notmatch 'android.permission.INTERNET'){ $s=$s -replace '<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">','<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">`r`n    <uses-permission android:name=\"android.permission.INTERNET\" />' }; $s=$s -replace 'android:label=\"[^\"]*\"','android:label=\"SineMatch\"'; Set-Content -LiteralPath $p -Value $s -Encoding UTF8"
if errorlevel 1 goto fail

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $f=Get-ChildItem 'android/app/src/main/kotlin' -Filter MainActivity.kt -Recurse ^| Select-Object -First 1; if($f){ $s=Get-Content -Raw $f.FullName; $s=$s -replace '(?m)^package\s+[^\r\n]+','package com.sinematch.app'; $t='android/app/src/main/kotlin/com/sinematch/app/MainActivity.kt'; New-Item -ItemType Directory -Force -Path (Split-Path $t) ^| Out-Null; Set-Content -LiteralPath $t -Value $s -Encoding UTF8; if($f.FullName -ne (Resolve-Path $t).Path){Remove-Item $f.FullName -Force} }"
if errorlevel 1 goto fail

:: Paketler ve ikonlar.
echo [8/9] Flutter paketleri ve SineMatch logosu uygulanıyor...
call "%FLUTTER_ROOT%\bin\flutter.bat" clean
call "%FLUTTER_ROOT%\bin\flutter.bat" pub get
if errorlevel 1 goto fail
call "%FLUTTER_ROOT%\bin\dart.bat" run flutter_launcher_icons
if errorlevel 1 goto fail

:: API adresi opsiyonel. Bos birakilirsa demo mod.
echo.
echo ================================================================
echo API ADRESI
echo ================================================================
echo Ornek: https://sinematch.com/api
echo Backend henuz kurulmadiysa BOS birak ve ENTER'a bas.
echo.
set "API_URL=https://site-demo.com.tr"
echo Varsayilan API: %API_URL%
set /p "CUSTOM_API=Farkli adres kullanacaksan yaz, ayni kalacaksa ENTER: "
if defined CUSTOM_API set "API_URL=%CUSTOM_API%"

echo.
echo [9/9] RELEASE APK derleniyor...
if defined API_URL (
  call "%FLUTTER_ROOT%\bin\flutter.bat" build apk --release --dart-define="SINEMATCH_API_URL=%API_URL%"
) else (
  call "%FLUTTER_ROOT%\bin\flutter.bat" build apk --release
)
if errorlevel 1 goto fail

set "APK_SOURCE=%PROJECT_DIR%build\app\outputs\flutter-apk\app-release.apk"
if not exist "%APK_SOURCE%" (
  echo [HATA] Build tamamlandi ancak APK bulunamadi.
  goto fail
)

if not exist "%PROJECT_DIR%dist" mkdir "%PROJECT_DIR%dist"
copy /Y "%APK_SOURCE%" "%PROJECT_DIR%dist\SineMatch-v%APP_VERSION%.apk" >nul

set "DESKTOP=%USERPROFILE%\Desktop"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%D"
if not exist "%DESKTOP%" mkdir "%DESKTOP%"
copy /Y "%APK_SOURCE%" "%DESKTOP%\SineMatch-v%APP_VERSION%.apk" >nul

cls
color 0A
echo ================================================================
echo                    APK HAZIR!
echo ================================================================
echo.
echo Dosya:
echo   %DESKTOP%\SineMatch-v%APP_VERSION%.apk
echo.
echo Proje kopyasi:
echo   %PROJECT_DIR%dist\SineMatch-v%APP_VERSION%.apk
echo.
echo Android Package ID: com.sinematch.app
echo.
explorer.exe /select,"%DESKTOP%\SineMatch-v%APP_VERSION%.apk"
echo ENTER ile kapatabilirsin.
pause >nul
exit /b 0

:fail
color 0C
echo.
echo ================================================================
echo KURULUM / BUILD TAMAMLANAMADI
echo ================================================================
echo.
echo Internet, disk alani ve Windows Update/App Installer durumunu kontrol et.
echo Hata ekranda yukarida gorunur. Bu pencerenin ekran goruntusunu bana atabilirsin.
echo.
pause
exit /b 1
