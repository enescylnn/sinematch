import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationService {
  NotificationService(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    if (AppConfig.demoMode) {
      final now = DateTime.now();
      return [
        AppNotification(id: 1, type: 'match', title: 'Yeni bir eşleşmen var!', body: 'Elif seninle eşleşti.', createdAt: now),
        AppNotification(id: 2, type: 'profile', title: 'Profilin görüntülendi', body: 'Bugün 3 kişi profilini görüntüledi.', createdAt: now.subtract(const Duration(minutes: 20))),
        AppNotification(id: 3, type: 'message', title: 'Yeni mesaj', body: 'Eşleşmen sana mesaj gönderdi.', createdAt: now.subtract(const Duration(hours: 1))),
        AppNotification(id: 4, type: 'ai', title: 'SineAI önerisi', body: 'Sana uygun yeni bir film listesi hazır.', createdAt: now.subtract(const Duration(hours: 2))),
      ];
    }
    final data = await _api.get('/notifications') as Map<String, dynamic>;
    return (data['notifications'] as List? ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    if (AppConfig.demoMode) return;
    await _api.post('/notifications/$id/read');
  }
}
