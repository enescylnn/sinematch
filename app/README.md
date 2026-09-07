# SineMatch Flutter App

## Gereksinimler
- Flutter 3.47+ / Dart 3.12+
- Android SDK 24+
- iOS 13+

## İlk hazırlık
```bash
flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
dart run flutter_launcher_icons
```

## Çalıştırma
```bash
flutter run --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr
```

API tanımlanmazsa demo modu açılır.

## Premium ürün IDs
- sinematch_premium_1m
- sinematch_premium_6m
- sinematch_premium_12m
