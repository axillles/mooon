import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../main.dart'; // Для доступа к bookingTimerController
import 'dart:convert'; // Добавляем для jsonDecode

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
    return deviceId;
  }

  // Получить id текущего пользователя (auth или deviceId)
  static Future<String> getCurrentUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    return await getDeviceId();
  }

  // Получить активное бронирование для устройства и сеанса
  static Future<Map<String, dynamic>?> getActiveBooking(int screeningId) async {
    final userId = await getCurrentUserId();
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
      final booking = bookings.first as Map<String, dynamic>;
      // Исправляем обработку seats
      final seatsData = booking['seats'];
      if (seatsData is String && seatsData.contains('-')) {
        // Если это строка вида "4-1", преобразуем в список
        booking['seats'] = [seatsData];
      }
      return booking;
    }
    return null;
  }

  // Создать или обновить бронирование
  static Future<void> createOrUpdateBooking(
    int screeningId,
    List<String> seats,
  ) async {
    final userId = await getCurrentUserId();
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
      // Добавляем в глобальное отслеживание
      bookingTimerController.addBooking(screeningId, now);
    } else {
      final response = await supabase
          .from('bookings')
          .update({'seats': seats, 'booking_time': now.toIso8601String()})
          .eq('id', active['id']);
      print('Update booking response: $response');
      // Обновляем время в глобальном отслеживании
      bookingTimerController.addBooking(screeningId, now);
    }
  }

  // Отменить бронирование
  static Future<void> cancelBooking(int screeningId) async {
    final active = await getActiveBooking(screeningId);
    if (active != null) {
      await supabase.from('bookings').delete().eq('id', active['id']);
      // Удаляем из глобального отслеживания
      bookingTimerController.removeBooking(screeningId);
    }
  }

  // Получить все занятые места для сеанса (pending и confirmed, не истекшие)
  static Future<Set<String>> getTakenSeats(
    int screeningId, {
    bool excludeCurrentUser = true,
  }) async {
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final currentUserId = excludeCurrentUser ? await getCurrentUserId() : null;
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
        final userId = b['user_id'] as String?;

        // Для confirmed мест - всегда добавляем в takenSeats
        // Для pending мест - исключаем места текущего пользователя, если excludeCurrentUser = true
        if (status == 'pending' &&
            excludeCurrentUser &&
            userId == currentUserId) {
          continue; // Исключаем pending места текущего пользователя
        }

        if (status == 'pending' &&
            (bookingTime == null || bookingTime.isBefore(fiveMinAgo))) {
          continue; // skip expired pending
        }
        final seatsData = b['seats'];
        List<dynamic>? seatsList;

        if (seatsData is String) {
          // Если seats - это строка вида "4-1", обрабатываем как одно место
          if (seatsData.contains('-')) {
            seatsList = [seatsData];
          } else {
            // Если это JSON массив в строке
            try {
              seatsList = jsonDecode(seatsData) as List<dynamic>;
            } catch (e) {
              print('Ошибка парсинга seats JSON: $e');
              seatsList = null;
            }
          }
        } else if (seatsData is List) {
          seatsList = seatsData;
        } else {
          seatsList = null;
        }

        if (seatsList != null) {
          for (final seat in seatsList) {
            taken.add(seat.toString());
          }
        }
      }
    }
    return taken;
  }

  // Проверить и отменить истекшие бронирования для всех сеансов
  static Future<List<int>> checkAndCancelExpiredBookings() async {
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));
    final expiredScreenings = <int>{};

    try {
      // Получаем все pending бронирования
      final pendingBookings = await supabase
          .from('bookings')
          .select()
          .eq('status', 'pending');

      if (pendingBookings is List) {
        for (final booking in pendingBookings) {
          final bookingTime =
              DateTime.tryParse(booking['booking_time'] ?? '')?.toUtc();
          if (bookingTime != null && bookingTime.isBefore(fiveMinAgo)) {
            final screeningId = booking['screening_id'] as int;
            expiredScreenings.add(screeningId);
            // Удаляем истекшее бронирование из БД
            await supabase.from('bookings').delete().eq('id', booking['id']);
            print('Удалено истекшее бронирование: ${booking['id']}');
            print('Отменено истекшее бронирование: ${booking['id']}');
          }
        }
      }
      return expiredScreenings.toList();
    } catch (e) {
      print('Ошибка при проверке истекших бронирований: $e');
      return [];
    }
  }

  // Проверить и отменить истекшие бронирования для конкретного сеанса
  static Future<void> checkAndCancelExpiredBookingsForScreening(
    int screeningId,
  ) async {
    final now = DateTime.now().toUtc();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));

    try {
      final pendingBookings = await supabase
          .from('bookings')
          .select()
          .eq('screening_id', screeningId)
          .eq('status', 'pending');

      if (pendingBookings is List) {
        for (final booking in pendingBookings) {
          final bookingTime =
              DateTime.tryParse(booking['booking_time'] ?? '')?.toUtc();
          if (bookingTime != null && bookingTime.isBefore(fiveMinAgo)) {
            await supabase.from('bookings').delete().eq('id', booking['id']);
            print(
              'Отменено истекшее бронирование для сеанса $screeningId: ${booking['id']}',
            );
          }
        }
      }
    } catch (e) {
      print(
        'Ошибка при проверке истекших бронирований для сеанса $screeningId: $e',
      );
    }
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

  // --- Аутентификация по телефону через Supabase ---
  static Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    return await supabase.auth.signUp(phone: phone, password: password);
  }

  static Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  static Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
    required String type,
  }) async {
    // type: 'sms' для подтверждения регистрации, 'recovery' для восстановления
    await supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // Получить активные билеты пользователя (будущие бронирования)
  static Future<List<Map<String, dynamic>>> getActiveUserBookings() async {
    final userId = await getCurrentUserId();
    final now = DateTime.now().toUtc();
    // Получаем все бронирования пользователя
    final bookings = await supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .filter('status', 'in', '("confirmed","active")')
        .order('booking_time', ascending: false);
    List<Map<String, dynamic>> result = [];
    for (final booking in bookings) {
      final screeningId = booking['screening_id'] as int;
      // Получаем сеанс
      final screeningList = await supabase
          .from('screenings')
          .select()
          .eq('id', screeningId);
      if (screeningList is List && screeningList.isNotEmpty) {
        final screening = screeningList.first;
        final startTime = DateTime.parse(screening['start_time']);
        if (startTime.isAfter(now)) {
          // Получаем фильм
          final movieList = await supabase
              .from('movies')
              .select()
              .eq('id', screening['movie_id']);
          final movie =
              movieList is List && movieList.isNotEmpty
                  ? movieList.first
                  : null;
          // Получаем зал
          final hallList = await supabase
              .from('halls')
              .select()
              .eq('id', screening['hall_id']);
          final hall =
              hallList is List && hallList.isNotEmpty ? hallList.first : null;
          // Получаем кинотеатр
          Map<String, dynamic>? cinema;
          if (hall != null) {
            final cinemaList = await supabase
                .from('cinemas')
                .select()
                .eq('id', hall['cinema_id']);
            cinema =
                cinemaList is List && cinemaList.isNotEmpty
                    ? cinemaList.first
                    : null;
          }
          result.add({
            'booking': booking,
            'screening': screening,
            'movie': movie,
            'hall': hall,
            'cinema': cinema,
          });
        }
      }
    }
    return result;
  }

  // Получить историю билетов пользователя (все бронирования)
  static Future<List<Map<String, dynamic>>> getUserBookingHistory() async {
    final userId = await getCurrentUserId();
    // Получаем все бронирования пользователя
    final bookings = await supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('booking_time', ascending: false);
    List<Map<String, dynamic>> result = [];
    for (final booking in bookings) {
      final screeningId = booking['screening_id'] as int;
      // Получаем сеанс
      final screeningList = await supabase
          .from('screenings')
          .select()
          .eq('id', screeningId);
      if (screeningList is List && screeningList.isNotEmpty) {
        final screening = screeningList.first;
        // Получаем фильм
        final movieList = await supabase
            .from('movies')
            .select()
            .eq('id', screening['movie_id']);
        final movie =
            movieList is List && movieList.isNotEmpty ? movieList.first : null;
        // Получаем зал
        final hallList = await supabase
            .from('halls')
            .select()
            .eq('id', screening['hall_id']);
        final hall =
            hallList is List && hallList.isNotEmpty ? hallList.first : null;
        // Получаем кинотеатр
        Map<String, dynamic>? cinema;
        if (hall != null) {
          final cinemaList = await supabase
              .from('cinemas')
              .select()
              .eq('id', hall['cinema_id']);
          cinema =
              cinemaList is List && cinemaList.isNotEmpty
                  ? cinemaList.first
                  : null;
        }
        // Получаем seatTypes для зала
        List<Map<String, dynamic>> seatTypes = [];
        if (hall != null) {
          final seatTypeIds = await supabase
              .from('seats')
              .select('seat_type_id')
              .eq('hall_id', hall['id']);
          final uniqueTypeIds =
              (seatTypeIds as List)
                  .map((e) => e['seat_type_id'])
                  .toSet()
                  .toList();
          if (uniqueTypeIds.isNotEmpty) {
            final idsStr = '(' + uniqueTypeIds.join(',') + ')';
            final types = await supabase
                .from('seat_types')
                .select()
                .filter('id', 'in', idsStr);
            if (types is List) seatTypes = types.cast<Map<String, dynamic>>();
          }
        }
        result.add({
          'booking': booking,
          'screening': screening,
          'movie': movie,
          'hall': hall,
          'cinema': cinema,
          'seatTypes': seatTypes,
        });
      }
    }
    return result;
  }

  // --- Profile ---

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final response =
          await supabase.from('profiles').select().eq('id', user.id).single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Пользователь не авторизован");
    await supabase.from('profiles').update(data).eq('id', user.id);
  }

  static Future<void> updateUserPassword(String newPassword) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Пользователь не авторизован");
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Начислить бонусы пользователю за заказ
  static Future<void> addBonusPoints({
    required String userId,
    required double orderAmountByN,
  }) async {
    // Получаем профиль пользователя
    final profile =
        await supabase.from('profiles').select().eq('id', userId).single();
    final int allTimePoints = profile['all_time_points'] ?? 0;
    // Определяем уровень
    final percent = allTimePoints >= 10000 ? 0.10 : 0.05;
    // Сколько рублей начислить бонусами
    final double bonusRub = orderAmountByN * percent;
    // Сколько баллов начислить (1 BYN = 100 баллов)
    final int bonusPoints = (bonusRub * 100).round();
    // Обновляем профиль
    await supabase
        .from('profiles')
        .update({
          'all_time_points': allTimePoints + bonusPoints,
          'current_points': (profile['current_points'] ?? 0) + bonusPoints,
        })
        .eq('id', userId);
  }
}
