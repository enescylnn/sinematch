import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/discovery_profile.dart';
import '../models/match_item.dart';
import 'demo_data.dart';

class SwipeResult {
  const SwipeResult({required this.matched, this.matchId});
  final bool matched;
  final int? matchId;
}

class MatchingService {
  MatchingService(this._api);
  final ApiClient _api;

  Future<List<DiscoveryProfile>> discover() async {
    if (AppConfig.demoMode) return demoProfiles;
    final data = await _api.get('/discover') as Map<String, dynamic>;
    return (data['profiles'] as List? ?? const [])
        .map((e) => DiscoveryProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SwipeResult> swipe(int userId, String action) async {
    if (AppConfig.demoMode) {
      return SwipeResult(matched: action != 'pass' && userId == demoProfiles.first.id, matchId: 1);
    }
    final data = await _api.post('/discover/$userId/swipe', body: {'action': action}) as Map<String, dynamic>;
    return SwipeResult(
      matched: data['matched'] == true,
      matchId: (data['match_id'] as num?)?.toInt(),
    );
  }

  Future<List<MatchItem>> matches() async {
    if (AppConfig.demoMode) return demoMatches;
    final data = await _api.get('/matches') as Map<String, dynamic>;
    return (data['matches'] as List? ?? const [])
        .map((e) => MatchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
