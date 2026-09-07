import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../core/storage/token_store.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._auth, this._store);

  final AuthService _auth;
  final TokenStore _store;

  AppUser? user;
  bool restoring = true;

  bool get isAuthenticated => user != null;
  bool get onboardingSeen => _store.onboardingSeen;

  Future<void> restore() async {
    restoring = true;
    notifyListeners();
    user = await _auth.restore();
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String identity, String password) async {
    final result = await _auth.login(identity, password);
    user = result.user;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String birthDate,
  }) async {
    final result = await _auth.register(
      name: name,
      username: username,
      email: email,
      password: password,
      birthDate: birthDate,
    );
    user = result.user;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _store.markOnboardingSeen();
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }
}
