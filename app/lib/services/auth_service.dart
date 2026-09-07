import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../models/app_user.dart';

class AuthResult {
  const AuthResult(this.user, this.token);
  final AppUser user;
  final String token;
}

class AuthService {
  AuthService(this._api, this._store);
  final ApiClient _api;
  final TokenStore _store;

  Future<AuthResult> login(String identity, String password) async {
    if (AppConfig.demoMode) {
      const user = AppUser(
        id: 1,
        displayName: 'Mert',
        username: 'mert',
        email: 'demo@sinematch.app',
        city: 'İstanbul',
        bio: 'İyi filmler, iyi insanlar, daha güzel sohbetler.',
      );
      const token = 'demo-token';
      await _store.setToken(token);
      return const AuthResult(user, token);
    }

    final data = await _api.post('/auth/login', body: {
      'identity': identity,
      'password': password,
    }) as Map<String, dynamic>;
    final token = data['token'].toString();
    await _store.setToken(token);
    return AuthResult(
      AppUser.fromJson(data['user'] as Map<String, dynamic>),
      token,
    );
  }

  Future<AuthResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String birthDate,
  }) async {
    if (AppConfig.demoMode) {
      final user = AppUser(
        id: 1,
        displayName: name,
        username: username,
        email: email,
        city: 'Türkiye',
      );
      const token = 'demo-token';
      await _store.setToken(token);
      return AuthResult(user, token);
    }

    final data = await _api.post('/auth/register', body: {
      'display_name': name,
      'username': username,
      'email': email,
      'password': password,
      'birth_date': birthDate,
    }) as Map<String, dynamic>;
    final token = data['token'].toString();
    await _store.setToken(token);
    return AuthResult(
      AppUser.fromJson(data['user'] as Map<String, dynamic>),
      token,
    );
  }

  Future<AppUser?> restore() async {
    if (_store.token == null) return null;
    if (AppConfig.demoMode) {
      return const AppUser(
        id: 1,
        displayName: 'Mert',
        username: 'mert',
        email: 'demo@sinematch.app',
        city: 'İstanbul',
        bio: 'İyi filmler, iyi insanlar, daha güzel sohbetler.',
      );
    }
    try {
      final data = await _api.get('/me') as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _store.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    if (!AppConfig.demoMode) {
      try {
        await _api.post('/auth/logout');
      } catch (_) {}
    }
    await _store.clearToken();
  }
}
