class MatchItem {
  const MatchItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.compatibility,
    this.avatarUrl,
    this.lastMessage,
    this.unread = 0,
  });

  final int id;
  final int userId;
  final String name;
  final int compatibility;
  final String? avatarUrl;
  final String? lastMessage;
  final int unread;

  factory MatchItem.fromJson(Map<String, dynamic> json) => MatchItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        name: json['display_name']?.toString() ?? 'Eşleşme',
        compatibility: (json['compatibility'] as num?)?.toInt() ?? 0,
        avatarUrl: json['avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString(),
        unread: (json['unread'] as num?)?.toInt() ?? 0,
      );
}
