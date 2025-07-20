import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart'; // Для доступа к bookingExpiredController
import 'dart:async'; // Импортируем для StreamSubscription

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? booking;
  Movie? movie;
  Hall? hall;
  Screening? screening;
  List<SeatType> seatTypes = [];
  List<Seat> seats = [];
  bool isLoading = true;
  StreamSubscription<int>? _expiredSubscription;

  @override
  void initState() {
    super.initState();
    // Подписываемся на уведомления об истечении бронирования
    _expiredSubscription = bookingExpiredController.stream.listen((
      screeningId,
    ) {
      if (booking != null && booking!['screening_id'] == screeningId) {
        _onBookingExpired();
      }
    });
    _loadBooking();
  }

  void _onBookingExpired() {
    // Показываем уведомление об истечении времени
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Время бронирования истекло. Кресла освобождены.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    // Возвращаемся на предыдущий экран
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _expiredSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    setState(() => isLoading = true);
    try {
      final userId = await SupabaseService.getDeviceId();
      final bookings = await SupabaseService.supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .order('booking_time', ascending: false);
      if (bookings is List && bookings.isNotEmpty) {
        final booking = bookings.first;
        setState(() {
          this.booking = booking;
        });
        await _loadRelatedData();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Ошибка при загрузке бронирования: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadRelatedData() async {
    if (booking == null) return;

    final screeningId = booking!['screening_id'] as int;
    final screeningList = await SupabaseService.supabase
        .from('screenings')
        .select()
        .eq('id', screeningId);
    if (screeningList is List && screeningList.isNotEmpty) {
      final screeningObj = Screening.fromJson(screeningList.first);
      final movieList = await SupabaseService.supabase
          .from('movies')
          .select()
          .eq('id', screeningObj.movieId);
      final hallList = await SupabaseService.supabase
          .from('halls')
          .select()
          .eq('id', screeningObj.hallId);
      final seatTypesList = await SupabaseService.getSeatTypes();
      final seatsList = await SupabaseService.getSeatsByHall(
        screeningObj.hallId,
      );

      // Проверяем, что виджет все еще активен
      if (!mounted) return;

      setState(() {
        movie = movieList.isNotEmpty ? Movie.fromJson(movieList.first) : null;
        hall = hallList.isNotEmpty ? Hall.fromJson(hallList.first) : null;
        screening = screeningObj;
        seatTypes = seatTypesList;
        seats = seatsList;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        booking = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        elevation: 0,
        title: const Text(
          'корзина',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body:
          isLoading
              ? Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
              : booking == null
              ? const Center(
                child: Text(
                  'Корзина пуста',
                  style: TextStyle(color: Colors.white70, fontSize: 22),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CartMovieTicketCard(
                      booking: booking!,
                      movie: movie,
                      hall: hall,
                      screening: screening,
                      seatTypes: seatTypes,
                      seats: seats,
                      onRemove: () async {
                        await SupabaseService.cancelBooking(
                          booking!['screening_id'],
                        );
                        setState(() => booking = null);
                      },
                    ),
                    const SizedBox(height: 18),
                    _CartSummary(
                      booking: booking!,
                      seatTypes: seatTypes,
                      seats: seats,
                    ),
                  ],
                ),
              ),
      // bottomNavigationBar убран
    );
  }
}

class _CartMovieTicketCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Movie? movie;
  final Hall? hall;
  final Screening? screening;
  final List<SeatType> seatTypes;
  final List<Seat> seats;
  final VoidCallback onRemove;
  const _CartMovieTicketCard({
    required this.booking,
    required this.movie,
    required this.hall,
    required this.screening,
    required this.seatTypes,
    required this.seats,
    required this.onRemove,
  });

  void _cancelBookingAndTimer() {
    SupabaseService.cancelBooking(booking['screening_id']);
    bookingTimerController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final seatKeys = (booking['seats'] as List?)?.cast<String>() ?? [];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movie != null && movie!.imageUrl.isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: Image.network(
                    movie!.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
                // Теги сверху
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Row(
                    children: [
                      if (movie!.ageRestriction > 0)
                        _Tag(text: '${movie!.ageRestriction}+'),
                      ...movie!.languages.map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _Tag(text: l),
                        ),
                      ),
                      ...movie!.technologies.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _Tag(text: t),
                        ),
                      ),
                    ],
                  ),
                ),
                // Основная информация внизу
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Теги убраны отсюда
                        // const SizedBox(height: 8),
                        Text(
                          movie!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                        if (hall != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              hall!.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (screening != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(screening!.startTime),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.access_time,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(screening!.startTime),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              if (hall != null) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hall!.name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ...seatKeys.map((seatKey) {
                  // Проверяем, что seats загружены
                  if (seats.isEmpty) {
                    return const SizedBox.shrink(); // Показываем пустой виджет пока данные загружаются
                  }

                  final seat = seats.firstWhere(
                    (s) => '${s.rowNumber}-${s.seatNumber}' == seatKey,
                    orElse:
                        () =>
                            seats.first, // Используем первое место как fallback
                  );

                  // Проверяем, что seatTypes загружены
                  if (seatTypes.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final seatType = seatTypes.firstWhere(
                    (t) => t.id == seat.seatTypeId,
                    orElse: () => seatTypes.first,
                  );
                  final price = seatType.price ?? 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23232A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          seatType.code == 'loveseat'
                              ? 'assets/images/loveseat.svg'
                              : seatType.code == 'sofa'
                              ? 'assets/images/sofa.svg'
                              : seatType.code == 'recliner'
                              ? 'assets/images/recliner.svg'
                              : seatType.code == 'loveseatrecliner' ||
                                  seatType.code == 'love_seat_recliner'
                              ? 'assets/images/loveSeatRecliner.svg'
                              : 'assets/images/single.svg',
                          width: 32,
                          height: 32,
                          color: const Color(0xFF6B7AFF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seatType.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              seat.rowNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'ряд',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              seat.seatNumber.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'место',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price.toStringAsFixed(2).replaceAll('.', ','),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'BYN',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final newSeats = List<String>.from(seatKeys)
                              ..remove(seatKey);
                            if (newSeats.isEmpty) {
                              _cancelBookingAndTimer();
                              onRemove();
                              // Если корзина пуста, возвращаемся на экран выбора кресел
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                              );
                            } else {
                              await SupabaseService.createOrUpdateBooking(
                                booking['screening_id'],
                                newSeats,
                              );
                              booking['seats'] = newSeats;
                              (context as Element).markNeedsBuild();
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white38,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _CartSummary extends StatelessWidget {
  final Map<String, dynamic> booking;
  final List<SeatType>? seatTypes;
  final List<Seat>? seats;
  const _CartSummary({required this.booking, this.seatTypes, this.seats});

  @override
  Widget build(BuildContext context) {
    final seatKeys = (booking['seats'] as List?)?.cast<String>() ?? [];
    double price = 0.0;
    if (seatTypes != null && seats != null) {
      for (final seatKey in seatKeys) {
        final seat = seats!.firstWhere(
          (s) => '${s.rowNumber}-${s.seatNumber}' == seatKey,
          orElse:
              () =>
                  seats!.isNotEmpty
                      ? seats!.first
                      : throw Exception('Нет мест'),
        );
        final seatType = seatTypes!.firstWhere(
          (t) => t.id == seat.seatTypeId,
          orElse: () => seatTypes!.first,
        );
        price += seatType.price ?? 0.0;
      }
    } else {
      price = 16.0 * seatKeys.length;
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Убрано поле 'Всего'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'К оплате:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${price.toStringAsFixed(2).replaceAll('.', ',')} BYN',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Вы сможете применить промокод, сертификат и воспользоваться бонусами на странице оплаты',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B7AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'К оплате',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
