// lib/appkk.dart
// Merkezi uygulama/konfigürasyon sınıfı — API URL'sini build-time dart-define ile alır.
// Varsayılan fallback: https://site-demo.com.tr
// Kullanım:
//   - Yerel/CI build: flutter build apk --release --dart-define=API_URL=https://site-demo.com.tr
//   - Kod içinde: AppKk.apiBase veya AppKk.endpoint('/v1/movies')

class AppKk {
  // Build sırasında --dart-define=API_URL=<url> verilmemişse bu default kullanılır.
  static const String apiBase =
      String.fromEnvironment('API_URL', defaultValue: 'https://site-demo.com.tr');

  /// API yolunu tam bir Uri olarak döndürür. `path` öneki `/` ile verilebilir veya verilmeden.
  static Uri endpoint(String path) {
    if (path.startsWith('/')) return Uri.parse('\$apiBase$path');
    return Uri.parse('\$apiBase/$path');
  }

  // İhtiyaç varsa ek yardımcı metodlar ekleyin, örn. headers, timeouts vs.
}
