# SineMatch Professional Starter

Bu paket iki ana bölümden oluşur:

- `app/` — Flutter Android + iOS istemcisi
- `backend/` — PHP 8.1+ / MySQL REST API, web kurulum ekranı ve basit yönetim paneli

## Hızlı kurulum

### 1) Backend
1. `backend/` klasörünü hosting üzerinde örneğin `public_html/api/` içine yükleyin.
2. MySQL veritabanı ve kullanıcı oluşturun.
3. Tarayıcıdan `https://site-demo.com.tr/install.php` adresini açın.
4. Veritabanı bilgilerini, admin hesabını ve isteğe bağlı AI/TMDB bilgilerini girin.
5. Kurulum tamamlandıktan sonra `install.php` dosyasını silin veya yeniden adlandırın.
6. Sağlık kontrolü: `https://site-demo.com.tr/health`

### 2) Flutter
Flutter 3.47+ önerilir.

```bash
cd app
flutter pub get
dart run flutter_launcher_icons
flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
flutter run --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr
```

> `flutter create .` komutunu bu pakette özellikle kurulum adımına bıraktık. Böylece Android/iOS native proje dosyaları kullandığınız Flutter sürümünün güncel şablonuyla oluşur ve `lib/`, `assets/` ve `pubspec.yaml` korunur.

### Android release
```bash
flutter build appbundle --release --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr
flutter build apk --release --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr
```

### iOS release
macOS + Xcode gerekir:
```bash
flutter build ipa --release --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr
```

## Demo modu
API adresi verilmezse uygulama yerel demo veriyle açılır. Gerçek kayıt, eşleşme ve mesajlaşma için backend URL'sini build sırasında verin.

## Premium
Flutter tarafı Apple App Store ve Google Play uyumlu `in_app_purchase` altyapısını kullanır. Ürün kimlikleri:

- `sinematch_premium_1m`
- `sinematch_premium_6m`
- `sinematch_premium_12m`

Bu ürünleri App Store Connect ve Google Play Console tarafında ayrıca oluşturmanız gerekir. Backend satın alma makbuzunu kaydeder. Production yayınında mağaza sunucu doğrulaması için Apple/Google servis hesaplarını ekleyin; development modunda demo doğrulama kullanılabilir.

## AI
AI anahtarı mobil uygulamaya yazılmaz. Hosting tarafında `backend/app/config.php` içinde tutulur. Kurulum ekranından OpenAI-compatible bir endpoint ve API key tanımlanabilir. Anahtar boşsa SineAI güvenli demo önerileri üretir.

## Güvenlik
- Parolalar `password_hash()` ile saklanır.
- Mobil oturum tokenları veritabanında hash olarak tutulur.
- Hazırlanmış PDO sorguları kullanılır.
- API rate limit ve bearer authentication içerir.
- Yönetim paneli ayrı admin oturumu kullanır.
- `backend/storage/` web erişimine kapatılmıştır.

## Not
Bu ortamda Flutter SDK / Xcode bulunmadığı için derlenmiş APK/IPA binary'si oluşturulamadı. Paket build-ready kaynak kod, backend ve build scriptlerini içerir.


## v1.0.2 TMDB Full Movie Sync
Admin paneline TMDB resmi Daily ID Export tabanlı, kaldığı yerden devam eden tam film kataloğu senkronu eklendi.
