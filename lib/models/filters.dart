class MovieFilters {
  final DateTime selectedDate;
  final double startTime;
  final double endTime;
  final String selectedCity;
  final int selectedSpaceIndex;
  final Set<String> selectedHalls;
  final Set<String> selectedTechnologies;
  final Set<String> selectedLanguages;
  final Set<String> selectedGenres;

  MovieFilters({
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.selectedCity,
    required this.selectedSpaceIndex,
    required this.selectedHalls,
    required this.selectedTechnologies,
    required this.selectedLanguages,
    required this.selectedGenres,
  });

  // Создаем пустые фильтры по умолчанию
  factory MovieFilters.empty() {
    return MovieFilters(
      selectedDate: DateTime.now(),
      startTime: 0,
      endTime: 24,
      selectedCity: 'Минск',
      selectedSpaceIndex: 0,
      selectedHalls: {},
      selectedTechnologies: {},
      selectedLanguages: {},
      selectedGenres: {},
    );
  }

  // Копирование с изменением отдельных полей
  MovieFilters copyWith({
    DateTime? selectedDate,
    double? startTime,
    double? endTime,
    String? selectedCity,
    int? selectedSpaceIndex,
    Set<String>? selectedHalls,
    Set<String>? selectedTechnologies,
    Set<String>? selectedLanguages,
    Set<String>? selectedGenres,
  }) {
    return MovieFilters(
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedSpaceIndex: selectedSpaceIndex ?? this.selectedSpaceIndex,
      selectedHalls: selectedHalls ?? this.selectedHalls,
      selectedTechnologies: selectedTechnologies ?? this.selectedTechnologies,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      selectedGenres: selectedGenres ?? this.selectedGenres,
    );
  }
}

class Hall {
  final int id;
  final int cinemaId;
  final String name;
  final int? capacity;
  final String? technology;

  Hall({
    required this.id,
    required this.cinemaId,
    required this.name,
    this.capacity,
    this.technology,
  });

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'] as int,
      cinemaId: json['cinema_id'] as int,
      name: json['name'] as String,
      capacity: json['capacity'] as int?,
      technology: json['technology'] as String?,
    );
  }
}

class Screening {
  final int id;
  final int movieId;
  final int hallId;
  final DateTime startTime;
  final double price;
  final String? format;

  Screening({
    required this.id,
    required this.movieId,
    required this.hallId,
    required this.startTime,
    required this.price,
    this.format,
  });

  factory Screening.fromJson(Map<String, dynamic> json) {
    return Screening(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      hallId: json['hall_id'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      price: (json['price'] as num).toDouble(),
      format: json['format'] as String?,
    );
  }
}

class Seat {
  final int id;
  final int hallId;
  final String rowNumber;
  final int seatNumber;
  final int seatTypeId;
  final double x;
  final double y;
  final double angle;

  Seat({
    required this.id,
    required this.hallId,
    required this.rowNumber,
    required this.seatNumber,
    required this.seatTypeId,
    required this.x,
    required this.y,
    required this.angle,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] as int,
      hallId: json['hall_id'] as int,
      rowNumber: json['row_number'].toString(),
      seatNumber: json['seat_number'] as int,
      seatTypeId: json['seat_type_id'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SeatType {
  final int id;
  final String name;
  final String code;
  final double? price;
  final String? description;

  SeatType({
    required this.id,
    required this.name,
    required this.code,
    this.price,
    this.description,
  });

  factory SeatType.fromJson(Map<String, dynamic> json) {
    return SeatType(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      description: json['description'] as String?,
    );
  }
}

class Booking {
  final int id;
  final int screeningId;
  final String userId;
  final List<String> seats;
  final DateTime bookingTime;
  final String status;

  Booking({
    required this.id,
    required this.screeningId,
    required this.userId,
    required this.seats,
    required this.bookingTime,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      screeningId: json['screening_id'] as int,
      userId: json['user_id'] as String,
      seats: (json['seats'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bookingTime: DateTime.parse(json['booking_time'] as String),
      status: json['status'] as String,
    );
  }
}
