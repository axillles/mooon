import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  // Получить уникальный идентификатор устройства (используем как user_id)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    print('DeviceId: $deviceId');
    return deviceId;
  }

  // Получить активное бронирование для устройства и сеанса
  static Future<Map<String, dynamic>?> getActiveBooking(int screeningId) async {
    final userId = await getDeviceId();
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final bookings = await supabase
        .from('bookings')
        .select()
        .eq('screening_id', screeningId)
        .eq('user_id', userId)
        .eq('status', 'pending')
        .gte('booking_time', fiveMinAgo.toIso8601String());
    print(
      'getActiveBooking: screeningId=$screeningId, userId=$userId, result=$bookings',
    );
    if (bookings is List && bookings.isNotEmpty) {
      return bookings.first as Map<String, dynamic>;
    }
    return null;
  }

  // Создать или обновить бронирование
  static Future<void> createOrUpdateBooking(
    int screeningId,
    List<String> seats,
  ) async {
    final userId = await getDeviceId();
    final now = DateTime.now().toUtc();
    final active = await getActiveBooking(screeningId);
    print(
      'createOrUpdateBooking: screeningId=$screeningId, userId=$userId, seats=$seats, active=$active',
    );
    if (active == null) {
      final response = await supabase.from('bookings').insert({
        'screening_id': screeningId,
        'user_id': userId,
        'seats': seats,
        'booking_time': now.toIso8601String(),
        'status': 'pending',
      });
      print('Insert booking response: $response');
    } else {
      final response = await supabase
          .from('bookings')
          .update({'seats': seats, 'booking_time': now.toIso8601String()})
          .eq('id', active['id']);
      print('Update booking response: $response');
    }
  }

  // Отменить бронирование
  static Future<void> cancelBooking(int screeningId) async {
    final active = await getActiveBooking(screeningId);
    if (active != null) {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', active['id']);
    }
  }

  // Получить все занятые места для сеанса (pending и confirmed, не истекшие)
  static Future<Set<String>> getTakenSeats(int screeningId) async {
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final bookings = await supabase
        .from('bookings')
        .select()
        .eq('screening_id', screeningId)
        .filter('status', 'in', '("pending","confirmed")');
    final taken = <String>{};
    if (bookings is List) {
      for (final b in bookings) {
        final status = b['status'] as String?;
        final bookingTime = DateTime.tryParse(b['booking_time'] ?? '')?.toUtc();
        if (status == 'pending' &&
            (bookingTime == null || bookingTime.isBefore(fiveMinAgo))) {
          continue; // skip expired pending
        }
        final seatsList = b['seats'] as List?;
        if (seatsList != null) {
          for (final seat in seatsList) {
            if (seat is String) taken.add(seat);
          }
        }
      }
    }
    return taken;
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

  // Получение залов по cinema_id
  static Future<List<Hall>> getHallsByCinema(int cinemaId) async {
    try {
      final response = await supabase
          .from('halls')
          .select()
          .eq('cinema_id', cinemaId);
      return (response as List).map((h) => Hall.fromJson(h)).toList();
    } catch (e) {
      print('Ошибка при получении залов: $e');
      return [];
    }
  }

  // Получение сеансов по фильму и дате
  static Future<List<Screening>> getScreenings({
    required int movieId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    try {
      final response = await supabase
          .from('screenings')
          .select()
          .eq('movie_id', movieId)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String());
      return (response as List).map((s) => Screening.fromJson(s)).toList();
    } catch (e) {
      print('Ошибка при получении сеансов: $e');
      return [];
    }
  }

  // Получение мест по hall_id
  static Future<List<Seat>> getSeatsByHall(int hallId) async {
    try {
      final response = await supabase
          .from('seats')
          .select()
          .eq('hall_id', hallId);
      return (response as List).map((s) => Seat.fromJson(s)).toList();
    } catch (e) {
      print('Ошибка при получении мест: $e');
      return [];
    }
  }

  // Получение всех типов кресел
  static Future<List<SeatType>> getSeatTypes() async {
    try {
      final response = await supabase.from('seat_types').select();
      return (response as List).map((t) => SeatType.fromJson(t)).toList();
    } catch (e) {
      print('Ошибка при получении типов кресел: $e');
      return [];
    }
  }

  // Получение процента заполненности зала для сеанса
  static Future<double> getHallFillPercent({
    required int screeningId,
    required int hallId,
  }) async {
    // Получаем все места в зале
    final seats = await getSeatsByHall(hallId);
    final totalSeats = seats.length;
    if (totalSeats == 0) return 0.0;

    // Получаем все активные бронирования для этого сеанса
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final bookings = await supabase
        .from('bookings')
        .select()
        .eq('screening_id', screeningId)
        .filter('status', 'in', '("pending","confirmed")');

    // Считаем занятые места (pending только если не истёк timeout)
    final takenSeatIds = <int>{};
    for (final booking in bookings) {
      final status = booking['status'] as String?;
      final bookingTime =
          DateTime.tryParse(booking['booking_time'] ?? '')?.toUtc();
      if (status == 'pending' &&
          (bookingTime == null || bookingTime.isBefore(fiveMinAgo))) {
        continue; // skip expired pending
      }
      final seatsList = booking['seats'] as List?;
      if (seatsList != null) {
        for (final seatId in seatsList) {
          if (seatId is int) takenSeatIds.add(seatId);
        }
      }
    }
    return takenSeatIds.length / totalSeats;
  }
}
