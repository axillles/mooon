class Movie {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String type;
  final int ageRestriction;
  final int durationMinutes;
  final DateTime startShowDate;
  final DateTime endShowDate;
  final List<String> genres;
  final String director;
  final List<String> actors;
  final double rating;
  final String trailerUrl;
  final List<int> cinemaIds;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.ageRestriction,
    required this.durationMinutes,
    required this.startShowDate,
    required this.endShowDate,
    required this.genres,
    required this.director,
    required this.actors,
    required this.rating,
    required this.trailerUrl,
    required this.cinemaIds,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      type: json['type'] as String,
      ageRestriction: json['age_restriction'] as int,
      durationMinutes: json['duration_minutes'] as int,
      startShowDate: DateTime.parse(json['start_show_date'] as String),
      endShowDate: DateTime.parse(json['end_show_date'] as String),
      genres: List<String>.from(json['genres'] as List),
      director: json['director'] as String,
      actors: List<String>.from(json['actors'] as List),
      rating: (json['rating'] as num).toDouble(),
      trailerUrl: json['trailer_url'] as String,
      cinemaIds: (json['cinema_ids'] as List).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'type': type,
      'age_restriction': ageRestriction,
      'duration_minutes': durationMinutes,
      'start_show_date': startShowDate.toIso8601String(),
      'end_show_date': endShowDate.toIso8601String(),
      'genres': genres,
      'director': director,
      'actors': actors,
      'rating': rating,
      'trailer_url': trailerUrl,
      'cinema_ids': cinemaIds,
    };
  }
}
