import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import '../services/supabase_service.dart';
import '../services/image_service.dart';
import 'movie_detail_screen.dart';
import 'filter_screen.dart';
import 'search_screen.dart';

// Универсальная функция для форматирования времени (часы и минуты)
String formatDuration(int durationMinutes) {
  int hours = durationMinutes ~/ 60;
  int minutes = durationMinutes % 60;
  return minutes == 0 ? '$hours ч' : '$hours ч $minutes мин';
}

class AfishaScreen extends StatefulWidget {
  const AfishaScreen({super.key});

  @override
  State<AfishaScreen> createState() => _AfishaScreenState();
}

class _AfishaScreenState extends State<AfishaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['сегодня', 'завтра', 'на неделю', 'скоро'];
  final List<String> _categories = [
    'Все',
    'Премьеры',
    'mooon+',
    'Детям',
    'Эксклюзивно',
  ];
  int _selectedCategory = 0;

  List<Movie> _movies = [];
  bool _isLoading = true;
  MovieFilters _currentFilters = MovieFilters.empty();

  // --- Добавлено для фильтрации по городу ---
  final List<String> cities = ['Минск', 'Гродно'];
  Map<int, String> cinemaIdToCity = {
    1: 'Минск',
    2: 'Минск',
    3: 'Гродно',
    4: 'Гродно',
  };

  // Маппинг ID кинотеатров к пространствам
  Map<int, int> cinemaIdToSpace = {
    1: 1, // mooon в Dana Mall
    2: 2, // Silver Screen в Arena City
    3: 3, // mooon в Palazzo
    4: 1, // mooon в другом городе
  };
  // ---

  final GlobalKey _cityKey = GlobalKey();
  OverlayEntry? _cityOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadMovies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _removeCityMenu();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final movies = switch (_tabController.index) {
        0 => await SupabaseService.getMoviesByDate(DateTime.now()),
        1 => await SupabaseService.getMoviesByDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
        2 => await SupabaseService.getMoviesForWeek(),
        3 => await SupabaseService.getUpcomingMovies(),
        _ => <Movie>[],
      };

      // Применяем фильтры
      final filtered =
          movies.where((movie) {
            // Фильтр по городу и кинотеатру
            if (!movie.cinemaIds.any(
              (id) =>
                  cinemaIdToCity[id] == _currentFilters.selectedCity &&
                  (_currentFilters.selectedSpaceIndex == 0 ||
                      cinemaIdToSpace[id] ==
                          _currentFilters.selectedSpaceIndex),
            )) {
              return false;
            }

            // Фильтр по залам
            if (_currentFilters.selectedHalls.isNotEmpty &&
                !movie.halls.any(
                  (hall) => _currentFilters.selectedHalls.contains(hall),
                )) {
              return false;
            }

            // Фильтр по технологиям
            if (_currentFilters.selectedTechnologies.isNotEmpty &&
                !movie.technologies.any(
                  (tech) => _currentFilters.selectedTechnologies.contains(tech),
                )) {
              return false;
            }

            // Фильтр по языкам
            if (_currentFilters.selectedLanguages.isNotEmpty &&
                !movie.languages.any(
                  (lang) => _currentFilters.selectedLanguages.contains(lang),
                )) {
              return false;
            }

            // Фильтр по жанрам
            if (_currentFilters.selectedGenres.isNotEmpty &&
                !movie.genres.any(
                  (genre) => _currentFilters.selectedGenres.contains(genre),
                )) {
              return false;
            }

            // Фильтр по времени
            final showTimes = movie.showTimes.where((time) {
              final hour = time.hour + time.minute / 60;
              return hour >= _currentFilters.startTime &&
                  hour <= _currentFilters.endTime;
            });
            if (showTimes.isEmpty) {
              return false;
            }

            return true;
          }).toList();

      setState(() {
        _movies = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Здесь можно добавить обработку ошибок
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadMovies();
    }
  }

  void _showCityMenu() {
    if (_cityOverlay != null) {
      _removeCityMenu();
      return;
    }
    final renderBox = _cityKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    _cityOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx < 8 ? 8 : offset.dx,
            top: offset.dy + renderBox.size.height + 6,
            width:
                (renderBox.size.width > MediaQuery.of(context).size.width - 16)
                    ? MediaQuery.of(context).size.width - 16
                    : renderBox.size.width,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 16,
                  minWidth: renderBox.size.width,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        cities.map((city) {
                          final isSelected =
                              city == _currentFilters.selectedCity;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _removeCityMenu();
                              if (city != _currentFilters.selectedCity) {
                                setState(() {
                                  _currentFilters = _currentFilters.copyWith(
                                    selectedCity: city,
                                  );
                                });
                                _loadMovies();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color:
                                        isSelected
                                            ? const Color(0xFF5B5BFF)
                                            : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      city,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFF5B5BFF)
                                                : Colors.white,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_cityOverlay!);
  }

  void _removeCityMenu() {
    _cityOverlay?.remove();
    _cityOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _removeCityMenu,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'mooon',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    key: _cityKey,
                    onTap: () {
                      if (_cityOverlay == null) {
                        _showCityMenu();
                      } else {
                        _removeCityMenu();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23232A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentFilters.selectedCity,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'главная',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const Icon(
                    Icons.arrow_right,
                    color: Colors.white38,
                    size: 18,
                  ),
                  const Text(
                    'афиша',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder:
                    (context, i) => GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: Column(
                        children: [
                          Text(
                            _categories[i],
                            style: TextStyle(
                              color:
                                  _selectedCategory == i
                                      ? Colors.white
                                      : Colors.white54,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (_selectedCategory == i)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 3,
                              width: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(
                        context,
                      ).push<MovieFilters>(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  FilterScreen(initialFilters: _currentFilters),
                        ),
                      );
                      if (result != null) {
                        setState(() => _currentFilters = result);
                        _loadMovies();
                      }
                    },
                    icon: const Icon(
                      Icons.filter_list,
                      color: Colors.white70,
                      size: 20,
                    ),
                    label: const Text(
                      'Выбрать фильтры',
                      style: TextStyle(color: Colors.white70),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23232A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _movies.isEmpty
                      ? const Center(child: Text('Нет доступных фильмов'))
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio:
                                  0.6, //увеличение/уменьшение карточки афиши
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _movies.length,
                        itemBuilder: (context, index) {
                          final movie = _movies[index];
                          return _MovieCard(movie: movie);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
          );
        },
        child: Stack(
          children: [
            // Постер
            Container(
              height: 440,
              width: double.infinity,
              child: Stack(
                children: [
                  ImageService.getImage(
                    movie.imageUrl,
                    width: double.infinity,
                    height: 440,
                  ),
                  // Градиент-переход внизу
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 110,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF111114)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Верхний блок: возраст и язык
            Positioned(
              top: 18,
              left: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23232A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${movie.ageRestriction}+',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (movie.languages.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23232A).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        movie.languages.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Нижний блок: название, жанр, время
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.92),
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.genres.join(', '),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDuration(movie.durationMinutes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
