import '../config/app_config.dart';
import '../core/network/api_client.dart';

class AiService {
  AiService(this._api);
  final ApiClient _api;

  Future<String> ask(String prompt, {int? matchId}) async {
    if (AppConfig.demoMode) {
      final p = prompt.toLowerCase();
      if (p.contains('eşleş') || p.contains('ortak')) {
        return 'İkinizin ortak zevkinde bilim kurgu ve gerilim öne çıkıyor. Bu akşam “Arrival” iyi bir ortak seçim; ardından “filmdeki dil fikri gerçek olsaydı hayatın değişir miydi?” diye sohbeti açabilirsin.';
      }
      if (p.contains('interstellar')) {
        return 'Interstellar seviyorsan Arrival, Contact, Moon ve Ad Astra iyi devam seçenekleri. Daha karanlık bir şey istersen Dark dizisine geçebilirsin.';
      }
      return 'Bu akşam tempolu ama duygusu güçlü bir şey için Dune: Part Two; daha düşünsel bir seçim için Arrival öneririm. Ruh halini söylersen listeyi daha da daraltabilirim.';
    }

    final data = await _api.post('/ai/recommend', body: {
      'prompt': prompt,
      if (matchId != null) 'match_id': matchId,
    }) as Map<String, dynamic>;
    return data['answer']?.toString() ?? 'Şu an bir öneri oluşturamadım.';
  }
}
