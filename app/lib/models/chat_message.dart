class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.type = 'text',
  });

  final int id;
  final int senderId;
  final String body;
  final DateTime createdAt;
  final String type;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        type: json['message_type']?.toString() ?? 'text',
      );
}
