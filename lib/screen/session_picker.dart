import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import '../services/supabase_service.dart';
import 'booking_screen.dart';
import 'movie_detail_screen.dart';

class SessionPicker extends StatefulWidget {
  final Movie movie;
  const SessionPicker({Key? key, required this.movie}) : super(key: key);

  @override
  State<SessionPicker> createState() => _SessionPickerState();
}

class _SessionPickerState extends State<SessionPicker> {
  String selectedCity = 'Минск';
  int selectedDateIndex = 0;
  late List<DateTime> dates;
  bool isLoading = true;
  List<Screening> screenings = [];
  Map<int, Hall> halls = {}; // hallId -> Hall
  Map<int, Map<String, dynamic>> cinemas =
      {}; // cinemaId -> {name, address, city}

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    dates = List.generate(14, (i) => today.add(Duration(days: i)));
    _loadCinemasAndScreenings();
  }

  Future<void> _loadCinemasAndScreenings() async {
    setState(() => isLoading = true);
    // Получаем все сеансы фильма на выбранную дату
    final date = dates[selectedDateIndex];
    final allScreenings = await SupabaseService.getScreenings(
      movieId: widget.movie.id,
      date: date,
    );
    // Получаем все залы для этих сеансов
    final hallIds = allScreenings.map((s) => s.hallId).toSet().toList();
    final List<Hall> fetchedHalls = [];
    for (final hallId in hallIds) {
      final hallList = await SupabaseService.supabase
          .from('halls')
          .select()
          .eq('id', hallId);
      if (hallList is List && hallList.isNotEmpty) {
        fetchedHalls.add(Hall.fromJson(hallList.first));
      }
    }
    // Получаем все кинотеатры для этих залов
    final cinemaIds = fetchedHalls.map((h) => h.cinemaId).toSet().toList();
    final Map<int, Map<String, dynamic>> fetchedCinemas = {};
    for (final cinemaId in cinemaIds) {
      final cinemaList = await SupabaseService.supabase
          .from('cinemas')
          .select()
          .eq('id', cinemaId);
      if (cinemaList is List && cinemaList.isNotEmpty) {
        fetchedCinemas[cinemaId] = cinemaList.first;
      }
    }
    // Фильтруем по выбранному городу
    final filteredCinemas =
        fetchedCinemas.entries
            .where((e) => e.value['city'] == selectedCity)
            .map((e) => e.key)
            .toSet();
    final filteredHalls =
        fetchedHalls
            .where((h) => filteredCinemas.contains(h.cinemaId))
            .toList();
    final filteredScreenings =
        allScreenings
            .where((s) => filteredHalls.any((h) => h.id == s.hallId))
            .toList();
    // Собираем мапы для быстрого доступа
    final Map<int, Hall> hallsMap = {for (var h in filteredHalls) h.id: h};
    setState(() {
      screenings = filteredScreenings;
      halls = hallsMap;
      cinemas = fetchedCinemas;
      isLoading = false;
    });
  }

  void _onCityChanged(String? city) {
    if (city != null && city != selectedCity) {
      setState(() => selectedCity = city);
      _loadCinemasAndScreenings();
    }
  }

  void _onDateChanged(int idx) {
    setState(() => selectedDateIndex = idx);
    _loadCinemasAndScreenings();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF23232A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Верхняя панель с крестиком и городом
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
                child: Row(
                  children: [
                    const Spacer(),
                    DropdownButton<String>(
                      value: selectedCity,
                      dropdownColor: const Color(0xFF23232A),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Минск', child: Text('Минск')),
                        DropdownMenuItem(
                          value: 'Гродно',
                          child: Text('Гродно'),
                        ),
                      ],
                      onChanged: _onCityChanged,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF23232A),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Информация о фильме
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF23232A), Color(0xFF18181C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            widget.movie.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie_outlined,
                                    color: Colors.white38,
                                    size: 32,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.movie.ageRestriction}+  ${widget.movie.genres.join(', ')}  •  ${formatDuration(widget.movie.durationMinutes)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => MovieDetailScreen(movie: widget.movie),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white12,
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Даты
              SizedBox(
                height: 84,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalSpacing = 3 * 14 + 2 * 16 + 4;
                    final cardWidth = (constraints.maxWidth - totalSpacing) / 4;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final date = dates[i];
                        final isSelected = i == selectedDateIndex;
                        const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
                        const months = [
                          'янв',
                          'фев',
                          'мар',
                          'апр',
                          'май',
                          'июн',
                          'июл',
                          'авг',
                          'сен',
                          'окт',
                          'ноя',
                          'дек',
                        ];
                        return GestureDetector(
                          onTap: () => _onDateChanged(i),
                          child: Container(
                            width: isSelected ? cardWidth - 2 : cardWidth,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF5B5BFF)
                                      : const Color(0xFF23232A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFF5B5BFF)
                                        : Colors.white.withOpacity(0.7),
                                width: 0.4,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  days[(date.weekday + 5) % 7],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  months[date.month - 1],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _buildScreeningsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreeningsList() {
    if (screenings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Нет сеансов на выбранную дату',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    // Группируем по кинотеатрам
    final Map<int, List<Screening>> screeningsByCinema = {};
    for (final s in screenings) {
      final hall = halls[s.hallId];
      if (hall == null) continue;
      final cinemaId = hall.cinemaId;
      screeningsByCinema.putIfAbsent(cinemaId, () => []).add(s);
    }
    List<Widget> widgets = [];
    for (final entry in screeningsByCinema.entries) {
      final cinemaId = entry.key;
      final cinema = cinemas[cinemaId];
      if (cinema == null) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cinema['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                cinema['address'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return SizedBox(
                    height: 150,
                    child: FutureBuilder<List<double>>(
                      future: Future.wait(
                        entry.value.map((screening) async {
                          final hall = halls[screening.hallId];
                          if (hall == null) return 0.0;
                          return await SupabaseService.getHallFillPercent(
                            screeningId: screening.id,
                            hallId: hall.id,
                          );
                        }),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final fillPercents = snapshot.data!;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: entry.value.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, i) {
                            final screening = entry.value[i];
                            final hall = halls[screening.hallId];
                            final fillPercent = fillPercents[i];
                            return SizedBox(
                              width: cardWidth,
                              child: GestureDetector(
                                onTap: () {
                                  final cinema = cinemas[hall?.cinemaId];
                                  if (cinema != null && hall != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => BookingScreen(
                                              movie: widget.movie,
                                              cinemaName: cinema['name'] ?? '',
                                              cinemaAddress:
                                                  cinema['address'] ?? '',
                                              hallName: hall.name,
                                              date: screening.startTime,
                                              time: _formatTime(
                                                screening.startTime,
                                              ),
                                              hallId: hall.id,
                                              screeningId:
                                                  screening.id, // <-- добавлено
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: _SessionCard(
                                  time: _formatTime(screening.startTime),
                                  hall: hall?.name ?? '',
                                  tech: hall?.technology ?? '',
                                  lang: screening.format ?? '',
                                  fillPercent: fillPercent,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: widgets);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

String formatDuration(int durationMinutes) {
  int hours = durationMinutes ~/ 60;
  int minutes = durationMinutes % 60;
  return minutes == 0 ? '$hours ч' : '$hours ч $minutes мин';
}

// 1. Подключить реальный процент заполненности зала
// Для примера: пусть будет функция getHallFillPercent(hallId) (заглушка, можно заменить на реальную логику)
double getHallFillPercent(int hallId) {
  // TODO: заменить на реальную логику подсчёта заполненности
  // Например, seatsTaken / seatsTotal
  // Сейчас просто рандом для примера:
  return (hallId % 10) / 10.0;
}

class _SessionCard extends StatelessWidget {
  final String time;
  final String hall;
  final String tech;
  final String lang;
  final double fillPercent;
  const _SessionCard({
    required this.time,
    required this.hall,
    required this.tech,
    required this.lang,
    required this.fillPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isVip = hall.toLowerCase().contains('vip');
    return Container(
      width: 180,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Center(
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    lang,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tech,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Прогресс-бар заполненности зала
          Container(
            width: double.infinity,
            height: 28,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF23232A),
            ),
            child: Stack(
              children: [
                // Градиентная заливка по заполненности
                FractionallySizedBox(
                  widthFactor: fillPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5BFF), Color(0xFFFF4B5C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    hall,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
