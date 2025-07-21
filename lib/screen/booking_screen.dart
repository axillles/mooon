import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import '../services/supabase_service.dart';
import 'dart:math';
import '../main.dart'; // Для доступа к bookingTimerController и bookingExpiredController
import 'cart_screen.dart';
import 'dart:async'; // Импортируем для StreamSubscription и Timer
import 'hall_seat_map.dart';
import 'booking_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Добавляем импорт

class BookingScreen extends StatefulWidget {
  final Movie movie;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName;
  final DateTime date;
  final String time;
  final int hallId;
  final int? screeningId; // Добавим screeningId для работы с бронированием

  const BookingScreen({
    Key? key,
    required this.movie,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.date,
    required this.time,
    required this.hallId,
    this.screeningId,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Seat> seats = [];
  List<SeatType> seatTypes = [];
  Set<String> selectedSeats = {};
  Set<String> takenSeats = {}; // TODO: заполнить из бронирований
  bool isLoading = true;
  StreamSubscription<int>? _expiredSubscription;
  StreamSubscription<int>? _changedSubscription;
  Timer? _updateTimer; // Таймер для периодического обновления карты
  bool _showExtendDialog = false;
  bool _extendDialogShown = false;
  RealtimeChannel? _bookingChannel; // Для realtime подписки
  RealtimeChannel? _seatsChannel; // Для подписки на seats
  Timer? _debounceTimer; // Для предотвращения частых обновлений

  @override
  void initState() {
    super.initState();

    // Подписываемся на уведомления об истечении бронирования
    _expiredSubscription = bookingExpiredController.stream.listen((
      screeningId,
    ) {
      if (widget.screeningId == screeningId) {
        _onBookingExpired();
      }
    });
    // Подписываемся на уведомления об изменениях бронирований
    _changedSubscription = bookingChangedController.stream.listen((
      screeningId,
    ) {
      if (widget.screeningId == screeningId) {
        _onBookingChanged();
      }
    });
    // Запускаем периодическое обновление карты каждые 10 секунд
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (widget.screeningId != null) {
        _updateTakenSeats();
      }
    });
    // --- Реалтайм подписка на bookings ---
    if (widget.screeningId != null) {
      _bookingChannel =
          Supabase.instance.client
              .channel('public:bookings')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'bookings',
                callback: (payload) {
                  final newRow = payload.newRecord;
                  final oldRow = payload.oldRecord;
                  if ((newRow != null &&
                          newRow['screening_id'] == widget.screeningId) ||
                      (oldRow != null &&
                          oldRow['screening_id'] == widget.screeningId)) {
                    _updateTakenSeats();
                  }
                },
              )
              .subscribe();
    }
    // --- Реалтайм подписка на seats (структура зала) ---
    _seatsChannel =
        Supabase.instance.client
            .channel('public:seats')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'seats',
              callback: (payload) {
                final newRow = payload.newRecord;
                final oldRow = payload.oldRecord;
                if ((newRow != null && newRow['hall_id'] == widget.hallId) ||
                    (oldRow != null && oldRow['hall_id'] == widget.hallId)) {
                  _loadAll();
                }
              },
            )
            .subscribe();
    _loadAll();
  }

  void _onBookingChanged() {
    // Обновляем занятые места
    _updateTakenSeats();
  }

  void _onBookingExpired() {
    setState(() {
      selectedSeats.clear();
    });
    bookingTimerController.stop();
    // Перезагружаем данные для обновления карты кресел
    _loadAll();
  }

  Future<void> _updateTakenSeats() async {
    if (widget.screeningId != null) {
      final newTakenSeats = await SupabaseService.getTakenSeats(
        widget.screeningId!,
        excludeCurrentUser: true,
      );
      setState(() {
        takenSeats = newTakenSeats;
      });
    }
  }

  @override
  void dispose() {
    _expiredSubscription?.cancel();
    _changedSubscription?.cancel();
    _updateTimer?.cancel();
    _debounceTimer?.cancel();
    // --- Отписка от realtime ---
    if (_bookingChannel != null) {
      Supabase.instance.client.removeChannel(_bookingChannel!);
      _bookingChannel = null;
    }
    if (_seatsChannel != null) {
      Supabase.instance.client.removeChannel(_seatsChannel!);
      _seatsChannel = null;
    }
    // Если пользователь уходит с экрана — отменяем бронирование, если нет выбранных мест
    if (selectedSeats.isEmpty && widget.screeningId != null) {
      SupabaseService.cancelBooking(widget.screeningId!);
      bookingTimerController.stop();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadAll() async {
    // Отменяем предыдущий debounce таймер
    _debounceTimer?.cancel();

    // Устанавливаем новый debounce таймер
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => isLoading = true);
      final loadedSeats = await SupabaseService.getSeatsByHall(widget.hallId);
      final loadedTypes = await SupabaseService.getSeatTypes();
      Set<String> taken = {};
      Set<String> restored = {};
      if (widget.screeningId != null) {
        taken = await SupabaseService.getTakenSeats(
          widget.screeningId!,
          excludeCurrentUser: true,
        );
        final booking = await SupabaseService.getActiveBooking(
          widget.screeningId!,
        );
        // Восстанавливаем только pending места в selectedSeats
        if (booking != null &&
            booking['seats'] is List &&
            booking['status'] == 'pending') {
          restored = Set<String>.from(
            booking['seats'].map((e) => e.toString()),
          );
        }
      }
      setState(() {
        seats = loadedSeats;
        seatTypes = loadedTypes;
        takenSeats = taken;
        selectedSeats = restored;
        isLoading = false;
      });
      // Если есть восстановленные места — запустить таймер
      if (restored.isNotEmpty && bookingTimerController.value == null) {
        bookingTimerController.start(widget.movie.title);
      }
    });
  }

  void _cancelBookingAndTimer() {
    if (widget.screeningId != null) {
      SupabaseService.cancelBooking(widget.screeningId!);
    }
    bookingTimerController.stop();
  }

  void _onSeatTap(String seatKey) {
    setState(() {
      final wasEmpty = selectedSeats.isEmpty;
      if (selectedSeats.contains(seatKey)) {
        selectedSeats.remove(seatKey);
      } else {
        selectedSeats.add(seatKey);
      }
      // Работа с бронированием в БД
      if (widget.screeningId != null) {
        if (selectedSeats.isNotEmpty) {
          SupabaseService.createOrUpdateBooking(
            widget.screeningId!,
            selectedSeats.toList(),
          );
          // Каждый раз при добавлении кресла сбрасываем таймер на 5 минут
          if (!selectedSeats.contains(seatKey)) {
            // Если кресло убрали — не сбрасываем таймер
            // (логика ниже)
          } else {
            bookingTimerController.start(widget.movie.title);
          }
        } else {
          _cancelBookingAndTimer();
        }
      }
    });
  }

  Seat? _findSeatByKey(String seatKey) {
    return seats.firstWhere(
      (s) => '${s.rowNumber}-${s.seatNumber}' == seatKey,
      orElse: () => null as Seat, // временно, заменим ниже
    );
  }

  SeatType? _findSeatTypeById(int? id) {
    if (id == null) return null;
    return seatTypes.firstWhere(
      (t) => t.id == id,
      orElse: () => null as SeatType, // временно, заменим ниже
    );
  }

  // Универсальная функция для форматирования времени (часы и минуты)
  String formatDuration(int durationMinutes) {
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;
    return minutes == 0 ? '$hours ч' : '$hours ч $minutes мин';
  }

  @override
  Widget build(BuildContext context) {
    final genres =
        widget.movie.genres.isNotEmpty ? widget.movie.genres.first : '';
    final duration = formatDuration(widget.movie.durationMinutes);

    final bodyContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Постер и описание
          Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: Image.network(widget.movie.imageUrl, fit: BoxFit.cover),
              ),
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'главная',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event_seat,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      genres,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Tag(text: '${widget.movie.ageRestriction}+'),
                    if (widget.movie.languages.isNotEmpty)
                      Tag(text: widget.movie.languages.first),
                    if (widget.movie.technologies.isNotEmpty)
                      Tag(text: widget.movie.technologies.first),
                    if (widget.movie.technologies.length > 1)
                      Tag(text: widget.movie.technologies[1]),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23232A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Переход на карточку фильма
                      Navigator.of(context).pop();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Подробнее',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Блок с датой, временем, залом
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Дата',
                    value: _formatDate(widget.date),
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                ),
                Expanded(
                  child: InfoCard(
                    title: 'Сеанс',
                    value: widget.time,
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                Expanded(
                  child: InfoCard(
                    title: 'Зал',
                    value: widget.hallName,
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.only(left: 8),
                  ),
                ),
              ],
            ),
          ),
          // Пространство
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF18181C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пространство',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.cinemaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.cinemaAddress,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Вкладка "Билеты"
          // Виртуальный зал
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Center(
              child:
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        height: 360,
                        child: HallSeatMap(
                          seats: seats,
                          seatTypes: seatTypes,
                          selectedSeats: selectedSeats,
                          takenSeats: takenSeats,
                          onSeatTap: _onSeatTap,
                        ),
                      ),
            ),
          ),
          // Секция билеты переносим сюда
          if (selectedSeats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Билеты',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...selectedSeats.map((seatKey) {
                    final seat =
                        seats
                            .where(
                              (s) =>
                                  '${s.rowNumber}-${s.seatNumber}' == seatKey,
                            )
                            .toList();
                    if (seat.isEmpty) return const SizedBox.shrink();
                    final type =
                        seatTypes
                            .where((t) => t.id == seat.first.seatTypeId)
                            .toList();
                    final price =
                        type.isNotEmpty ? type.first.price ?? 0.0 : 0.0;
                    final iconAsset = () {
                      switch (type.isNotEmpty ? type.first.code : '') {
                        case 'loveseat':
                          return 'assets/images/loveseat.svg';
                        case 'sofa':
                          return 'assets/images/sofa.svg';
                        case 'recliner':
                          return 'assets/images/recliner.svg';
                        case 'loveseatrecliner':
                        case 'love_seat_recliner':
                          return 'assets/images/loveSeatRecliner.svg';
                        default:
                          return 'assets/images/single.svg';
                      }
                    }();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181C),
                          border: Border.all(color: Colors.white24, width: 1.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: SvgPicture.asset(
                                iconAsset,
                                width: 32,
                                height: 32,
                                color: const Color(0xFF6B7AFF),
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  type.isNotEmpty ? type.first.name : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 1,
                                    color: Colors.white24,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          seat.first.rowNumber,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'ряд',
                                          style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 48,
                                    width: 1,
                                    color: Colors.white24,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          seat.first.seatNumber.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'место',
                                          style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 48,
                                    width: 1,
                                    color: Colors.white24,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          price
                                              .toStringAsFixed(2)
                                              .replaceAll('.', ','),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'BYN',
                                          style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedSeats.remove(seatKey);
                                          if (selectedSeats.isEmpty)
                                            _cancelBookingAndTimer();
                                        });
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Итого:',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selectedSeats
                              .map((seatKey) {
                                final seat =
                                    seats
                                        .where(
                                          (s) =>
                                              '${s.rowNumber}-${s.seatNumber}' ==
                                              seatKey,
                                        )
                                        .toList();
                                if (seat.isEmpty) return 0.0;
                                final type =
                                    seatTypes
                                        .where(
                                          (t) => t.id == seat.first.seatTypeId,
                                        )
                                        .toList();
                                return type.isNotEmpty
                                    ? type.first.price ?? 0.0
                                    : 0.0;
                              })
                              .fold<double>(
                                0.0,
                                (a, b) => a + (b is num ? b.toDouble() : 0.0),
                              )
                              .toStringAsFixed(2)
                              .replaceAll('.', ','),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BYN',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadAll();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6B7AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 0,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'В корзину',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          // Сноска "Статус мест"
          if (!isLoading && seats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
              child: SeatStatusLegend(),
            ),
          // Сноска "Типы мест"
          if (!isLoading && seats.isNotEmpty && seatTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SeatTypesLegend(seats: seats, seatTypes: seatTypes),
            ),
        ],
      ),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF111114),
          body: SafeArea(child: bodyContent),
        ),
        // Всплывающее окно продления времени
        ValueListenableBuilder<BookingTimerState?>(
          valueListenable: bookingTimerController,
          builder: (context, state, _) {
            if (state == null || _extendDialogShown)
              return const SizedBox.shrink();
            final remaining = state.endTime.difference(DateTime.now());
            if (remaining.inSeconds <= 60 && !_showExtendDialog) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _showExtendDialog = true;
                  _extendDialogShown = true;
                });
              });
            }
            return _showExtendDialog
                ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: ExtendTimeDialog(
                    onClose: () {
                      setState(() => _showExtendDialog = false);
                    },
                    onExtend: () async {
                      setState(() => _showExtendDialog = false);
                      if (widget.screeningId != null &&
                          selectedSeats.isNotEmpty) {
                        await SupabaseService.createOrUpdateBooking(
                          widget.screeningId!,
                          selectedSeats.toList(),
                        );
                        bookingTimerController.start(widget.movie.title);
                      }
                    },
                  ),
                )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}
