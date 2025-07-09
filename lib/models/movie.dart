class Movie {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> galleryUrls;
  final int ageRestriction;
  final int durationMinutes;
  final List<String> genres;
  final List<int> cinemaIds;
  final List<String> halls;
  final List<String> technologies;
  final List<String> languages;
  final List<DateTime> showTimes;
  final String director;
  final String movieCast;
  final String trailerUrl;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.galleryUrls,
    required this.ageRestriction,
    required this.durationMinutes,
    required this.genres,
    required this.cinemaIds,
    required this.halls,
    required this.technologies,
    required this.languages,
    required this.showTimes,
    required this.director,
    required this.movieCast,
    required this.trailerUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      galleryUrls: (json['gallery_urls'] as List?)?.cast<String>() ?? [],
      ageRestriction: json['age_restriction'] as int,
      durationMinutes: json['duration_minutes'] as int,
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      cinemaIds: (json['cinema_ids'] as List?)?.cast<int>() ?? [],
      halls: (json['halls'] as List?)?.cast<String>() ?? [],
      technologies: (json['technologies'] as List?)?.cast<String>() ?? [],
      languages: (json['languages'] as List?)?.cast<String>() ?? [],
      showTimes:
          ((json['show_times'] as List?) ?? [])
              .map((time) => DateTime.parse(time as String))
              .toList(),
      director: json['director'] as String,
      movieCast: json['movie_cast'] as String,
      trailerUrl: json['trailer_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'gallery_urls': galleryUrls,
      'age_restriction': ageRestriction,
      'duration_minutes': durationMinutes,
      'genres': genres,
      'cinema_ids': cinemaIds,
      'halls': halls,
      'technologies': technologies,
      'languages': languages,
      'show_times': showTimes.map((time) => time.toIso8601String()).toList(),
      'director': director,
      'movie_cast': movieCast,
      'trailer_url': trailerUrl,
    };
  }
}
