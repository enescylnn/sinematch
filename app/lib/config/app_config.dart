class AppConfig {
  static const String appName = 'SineMatch';
  static const String apiBaseUrl = String.fromEnvironment(
    'SINEMATCH_API_URL',
    defaultValue: 'https://site-demo.com.tr',
  );

  static bool get demoMode => apiBaseUrl.trim().isEmpty;

  static const premiumProductIds = <String>{
    'sinematch_premium_1m',
    'sinematch_premium_6m',
    'sinematch_premium_12m',
  };
}
