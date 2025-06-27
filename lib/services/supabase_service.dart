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
    final response = await supabase
        .from('movies')
        .select()
        .lte('start_show_date', date.toIso8601String())
        .gte('end_show_date', date.toIso8601String());

    return (response as List).map((movie) => Movie.fromJson(movie)).toList();
  }

  // Получение фильмов на неделю
  static Future<List<Movie>> getMoviesForWeek() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));

    final response = await supabase
        .from('movies')
        .select()
        .gte('start_show_date', now.toIso8601String())
        .lte('start_show_date', weekLater.toIso8601String());

    return (response as List).map((movie) => Movie.fromJson(movie)).toList();
  }

  // Получение предстоящих фильмов
  static Future<List<Movie>> getUpcomingMovies() async {
    final now = DateTime.now();

    final response = await supabase
        .from('movies')
        .select()
        .gt('start_show_date', now.toIso8601String())
        .order('start_show_date');

    return (response as List).map((movie) => Movie.fromJson(movie)).toList();
  }
}
