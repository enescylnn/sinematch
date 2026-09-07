import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/movie.dart';
import 'demo_data.dart';

class CatalogService {
  CatalogService(this._api);
  final ApiClient _api;

  Future<List<Movie>> movies({String search = '', String genre = ''}) async {
    if (AppConfig.demoMode) {
      return demoMovies.where((movie) {
        final q = search.trim().toLowerCase();
        final g = genre.trim().toLowerCase();
        final searchOk = q.isEmpty || movie.title.toLowerCase().contains(q);
        final genreOk = g.isEmpty || movie.genres.any((x) => x.toLowerCase() == g);
        return searchOk && genreOk;
      }).toList();
    }
    final data = await _api.get('/movies', query: {
      if (search.isNotEmpty) 'search': search,
      if (genre.isNotEmpty) 'genre': genre,
      'limit': 40,
    }) as Map<String, dynamic>;
    return (data['movies'] as List? ?? const [])
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Movie> movie(int id) async {
    if (AppConfig.demoMode) return demoMovies.firstWhere((m) => m.id == id);
    final data = await _api.get('/movies/$id') as Map<String, dynamic>;
    return Movie.fromJson(data['movie'] as Map<String, dynamic>);
  }

  Future<void> action(int movieId, String action, {double? rating}) async {
    if (AppConfig.demoMode) return;
    await _api.post('/movies/$movieId/action', body: {
      'action': action,
      if (rating != null) 'rating': rating,
    });
  }
}
