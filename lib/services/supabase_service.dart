import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // Инициализация Supabase (вызывать в main.dart)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ngwvwmwtqcdqhhtmhbyv.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nd3Z3bXd0cWNkcWhodG1oYnl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2NzIyODUsImV4cCI6MjA2NjI0ODI4NX0.5PGutE0vzwIL3utI-O31N4WF9zco4Jv0BQxUDkJSq-A',
    );
  }

  // Получение фильмов по дате показа
  static Future<List<Movie>> getMoviesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      print('Fetching movies for date: ${startOfDay.toIso8601String()}');

      final response = await supabase
          .from('movies')
          .select()
          .neq(
            'show_times',
            '{}',
          ); // Получаем все фильмы, у которых есть сеансы

      print('Got response: $response');

      final movies =
          (response as List).map((movie) => Movie.fromJson(movie)).toList();

      // Фильтруем фильмы с сеансами на указанную дату
      return movies.where((movie) {
        return movie.showTimes.any((showTime) {
          final showDate = DateTime(
            showTime.year,
            showTime.month,
            showTime.day,
          );
          return showDate.isAtSameMomentAs(startOfDay);
        });
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching movies: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Получение фильмов на неделю
  static Future<List<Movie>> getMoviesForWeek() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final dates = List.generate(
      7,
      (i) => now.add(Duration(days: i)).toIso8601String(),
    );

    try {
      print(
        'Fetching movies for week from ${now.toIso8601String()} to ${weekLater.toIso8601String()}',
      );

      final response = await supabase
          .from('movies')
          .select()
          .neq('show_times', '{}');

      print('Got response: $response');

      final movies =
          (response as List).map((movie) => Movie.fromJson(movie)).toList();

      // Фильтруем фильмы с сеансами на ближайшую неделю
      return movies.where((movie) {
        return movie.showTimes.any((showTime) {
          return showTime.isAfter(now) && showTime.isBefore(weekLater);
        });
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching movies: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Получение предстоящих фильмов
  static Future<List<Movie>> getUpcomingMovies() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));

    try {
      print('Fetching upcoming movies after ${weekLater.toIso8601String()}');

      final response = await supabase
          .from('movies')
          .select()
          .neq('show_times', '{}');

      print('Got response: $response');

      final movies =
          (response as List).map((movie) => Movie.fromJson(movie)).toList();

      // Фильтруем фильмы, которые начнут показывать после следующей недели
      return movies.where((movie) {
        return movie.showTimes.any((showTime) => showTime.isAfter(weekLater));
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching movies: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
