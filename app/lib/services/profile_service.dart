import '../config/app_config.dart';
import '../core/network/api_client.dart';

class ProfileService {
  ProfileService(this._api);
  final ApiClient _api;

  Future<void> saveTastes({
    required List<String> genres,
    required List<String> lookingFor,
    List<String> favoriteMovies = const [],
    List<String> favoriteSeries = const [],
    List<String> favoriteActors = const [],
  }) async {
    if (AppConfig.demoMode) return;
    await _api.post('/me/tastes', body: {
      'genres': genres,
      'looking_for': lookingFor,
      'favorite_movies': favoriteMovies,
      'favorite_series': favoriteSeries,
      'favorite_actors': favoriteActors,
    });
  }
}
