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
