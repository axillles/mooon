import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/supabase_service.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<Movie> _allMovies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final movies = await SupabaseService.getMoviesForWeek();
      setState(() {
        _allMovies = movies;
        _filteredMovies = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allMovies = [];
        _filteredMovies = [];
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      final trimmed = _query.trim().toLowerCase();
      if (trimmed.isEmpty) {
        _filteredMovies = [];
      } else {
        // Проверяем, совпадает ли запрос с каким-либо жанром
        final allGenres = _allMovies.expand((m) => m.genres).toSet();
        final genreMatch = allGenres.firstWhere(
          (g) => g.toLowerCase() == trimmed,
          orElse: () => '',
        );
        if (genreMatch.isNotEmpty) {
          _filteredMovies =
              _allMovies
                  .where(
                    (movie) =>
                        movie.genres.any((g) => g.toLowerCase() == trimmed),
                  )
                  .toList();
        } else {
          _filteredMovies =
              _allMovies
                  .where((movie) => movie.title.toLowerCase().contains(trimmed))
                  .toList();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF323232),
      body: SafeArea(
        child: Stack(
          children: [
            // Крестик справа сверху
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF323232),
                    size: 28,
                  ),
                ),
              ),
            ),
            // Основное содержимое
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                    cursorColor: const Color(0xFF5B5BFF),
                    decoration: InputDecoration(
                      hintText: 'введите, например, Человек паук',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5B5BFF),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5B5BFF),
                          width: 2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onChanged: _onQueryChanged,
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Результат поиска',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _query.isEmpty
                          ? const SizedBox.shrink()
                          : _filteredMovies.isEmpty
                          ? const Center(
                            child: Text(
                              'Ничего не найдено',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 20,
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _filteredMovies.length,
                            itemBuilder: (context, index) {
                              final movie = _filteredMovies[index];
                              return Card(
                                color: const Color(0xFF23232A),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading:
                                      movie.imageUrl.isNotEmpty
                                          ? Image.network(
                                            movie.imageUrl,
                                            width: 56,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          )
                                          : const SizedBox(
                                            width: 56,
                                            height: 80,
                                          ),
                                  title: Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    movie.genres.join(', '),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                MovieDetailScreen(movie: movie),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
