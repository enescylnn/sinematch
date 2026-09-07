class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    this.city,
    this.avatarUrl,
    this.bio,
    this.isPremium = false,
    this.age,
  });

  final int id;
  final String displayName;
  final String username;
  final String email;
  final String? city;
  final String? avatarUrl;
  final String? bio;
  final bool isPremium;
  final int? age;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        displayName: json['display_name']?.toString() ?? json['name']?.toString() ?? 'SineMatch Kullanıcısı',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        city: json['city']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        bio: json['bio']?.toString(),
        isPremium: json['is_premium'] == true || json['is_premium'] == 1,
        age: (json['age'] as num?)?.toInt(),
      );

  AppUser copyWith({
    String? displayName,
    String? city,
    String? avatarUrl,
    String? bio,
    bool? isPremium,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username,
      email: email,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isPremium: isPremium ?? this.isPremium,
      age: age,
    );
  }
}
