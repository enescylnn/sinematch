class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.compatibility,
    required this.city,
    required this.age,
    required this.favoriteTitles,
    this.avatarUrl,
    this.bio = '',
    this.isPremium = false,
  });

  final int id;
  final String name;
  final int compatibility;
  final String city;
  final int age;
  final List<String> favoriteTitles;
  final String? avatarUrl;
  final String bio;
  final bool isPremium;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) => DiscoveryProfile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['display_name']?.toString() ?? 'Kullanıcı',
        compatibility: (json['compatibility'] as num?)?.toInt() ?? 50,
        city: json['city']?.toString() ?? 'Türkiye',
        age: (json['age'] as num?)?.toInt() ?? 25,
        favoriteTitles: (json['favorite_titles'] as List? ?? const []).map((e) => e.toString()).toList(),
        avatarUrl: json['avatar_url']?.toString(),
        bio: json['bio']?.toString() ?? '',
        isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      );
}
