import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/chat_message.dart';
import 'demo_data.dart';

class ChatService {
  ChatService(this._api);
  final ApiClient _api;
  final Map<int, List<ChatMessage>> _demo = {};

  Future<List<ChatMessage>> messages(int matchId, int myUserId) async {
    if (AppConfig.demoMode) {
      return _demo.putIfAbsent(matchId, () => demoMessages(myUserId));
    }
    final data = await _api.get('/matches/$matchId/messages') as Map<String, dynamic>;
    return (data['messages'] as List? ?? const [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(int matchId, int myUserId, String body) async {
    if (AppConfig.demoMode) {
      final list = _demo.putIfAbsent(matchId, () => demoMessages(myUserId));
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: myUserId,
        body: body,
        createdAt: DateTime.now(),
      );
      list.add(msg);
      return msg;
    }
    final data = await _api.post('/matches/$matchId/messages', body: {
      'body': body,
      'message_type': 'text',
    }) as Map<String, dynamic>;
    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }
}
