class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.type,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    this.rating = 0,
    this.genres = const [],
  });

  final int id;
  final String title;
  final String overview;
  final String type;
  final String? posterUrl;
  final String? backdropUrl;
  final int? year;
  final double rating;
  final List<String> genres;

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? 'İsimsiz',
        overview: json['overview']?.toString() ?? '',
        type: json['type']?.toString() ?? 'movie',
        posterUrl: json['poster_url']?.toString(),
        backdropUrl: json['backdrop_url']?.toString(),
        year: (json['release_year'] as num?)?.toInt(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        genres: (json['genres'] as List? ?? const []).map((e) => e.toString()).toList(),
      );
}
