# SineMatch APK / iOS build

## Android APK
Linux/macOS:
```bash
./scripts/build_apk.sh https://alanadiniz.com/api
```
Windows:
```bat
scripts\build_apk_windows.bat https://alanadiniz.com/api
```
Backend adresi verilmezse uygulama demo modunda açılır.

Çıktı:
`dist/SineMatch-v1.0.0.apk`

## Google Play AAB
```bash
./scripts/build_aab.sh https://alanadiniz.com/api
```

## iOS
macOS + Xcode gerektirir:
```bash
./scripts/build_ios.sh https://alanadiniz.com/api
```
Bu komut unsigned Runner.app üretir. App Store/TestFlight için Apple Developer signing gerekir.

## Kimlikler
- Android applicationId: `com.sinematch.app`
- iOS bundle id hedefi: `com.sinematch.app`
- Min Android SDK: 24
