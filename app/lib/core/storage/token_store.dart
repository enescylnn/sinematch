import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _onboardingKey = 'onboarding_seen';

  static Future<TokenStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStore(prefs);
  }

  String? get token => _prefs.getString(_tokenKey);
  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setToken(String token) => _prefs.setString(_tokenKey, token);
  Future<void> clearToken() => _prefs.remove(_tokenKey);
  Future<void> markOnboardingSeen() => _prefs.setBool(_onboardingKey, true);
}
