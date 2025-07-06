import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import '../services/supabase_service.dart';
import 'booking_screen.dart';

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
                            '${widget.movie.ageRestriction}+  ${widget.movie.genres.join(', ')}  •  ${widget.movie.durationMinutes ~/ 60} ч ${widget.movie.durationMinutes % 60} мин',
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
                    Icon(Icons.info_outline, color: Colors.white38),
                  ],
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
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: const Color(0xFF5B5BFF),
                                        width: 2,
                                      )
                                      : null,
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
                '${cinema['name']}   ${cinema['address']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final screening = entry.value[i];
                    final hall = halls[screening.hallId];
                    return GestureDetector(
                      onTap: () {
                        final cinema = cinemas[hall?.cinemaId];
                        if (cinema != null && hall != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => BookingScreen(
                                    movie: widget.movie,
                                    cinemaName: cinema['name'] ?? '',
                                    cinemaAddress: cinema['address'] ?? '',
                                    hallName: hall.name,
                                    date: screening.startTime,
                                    time: _formatTime(screening.startTime),
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
                      ),
                    );
                  },
                ),
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

class _SessionCard extends StatelessWidget {
  final String time;
  final String hall;
  final String tech;
  final String lang;
  const _SessionCard({
    required this.time,
    required this.hall,
    required this.tech,
    required this.lang,
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
          isVip
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B5BFF), Color(0xFFFF4B5C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Center(
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
              )
              : Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23232A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
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
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        color: const Color(0xFF5B5BFF),
                      ),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
