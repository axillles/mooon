import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'screen/afisha_screen.dart';
import 'screen/profile_screen.dart';
import 'services/supabase_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:ui';
import 'screen/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await initializeDateFormatting('ru', null);
  runApp(const EntryPoint());
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  bool? _showAuth;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final seenAuth = prefs.getBool('seen_auth') ?? false;
    setState(() {
      _showAuth = !seenAuth;
    });
  }

  void _onAuthSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_auth', true);
    setState(() {
      _showAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuth == null) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF23232A),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_showAuth == true) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthScreenWithCallback(onSuccess: _onAuthSuccess),
        theme: ThemeData.dark(),
      );
    }
    return const MyApp();
  }
}

class AuthScreenWithCallback extends StatelessWidget {
  final VoidCallback onSuccess;
  const AuthScreenWithCallback({required this.onSuccess, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthScreenWithLogic(onSuccess: onSuccess);
  }
}

class AuthScreenWithLogic extends StatefulWidget {
  final VoidCallback onSuccess;
  const AuthScreenWithLogic({required this.onSuccess, Key? key})
    : super(key: key);

  @override
  State<AuthScreenWithLogic> createState() => _AuthScreenWithLogicState();
}

class _AuthScreenWithLogicState extends State<AuthScreenWithLogic> {
  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      key: widget.key,
      onSuccess: widget.onSuccess, // <--- вот это добавляем!
    );
  }
}

// Глобальный стрим для уведомлений об истечении бронирования
final StreamController<int> bookingExpiredController =
    StreamController<int>.broadcast();

// Глобальный стрим для уведомлений об изменениях бронирований
final StreamController<int> bookingChangedController =
    StreamController<int>.broadcast();

// Глобальный контроллер таймера бронирования
class BookingTimerController extends ValueNotifier<BookingTimerState?> {
  BookingTimerController() : super(null);

  Timer? _timer;
  Timer? _checkTimer; // Таймер для проверки всех бронирований
  Map<int, DateTime> _activeBookings = {}; // screeningId -> bookingTime

  void start(
    String movieTitle, {
    Duration duration = const Duration(minutes: 5),
  }) {
    _timer?.cancel();
    value = BookingTimerState(
      movieTitle: movieTitle,
      endTime: DateTime.now().add(duration),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _startGlobalCheck();
  }

  void stop() {
    _timer?.cancel();
    value = null;
  }

  void _startGlobalCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkAllBookings(),
    );
  }

  void _checkAllBookings() async {
    try {
      final expiredScreenings =
          await SupabaseService.checkAndCancelExpiredBookings();
      // Уведомляем экраны об истечении бронирований
      for (final screeningId in expiredScreenings) {
        bookingExpiredController.add(screeningId);
      }
      // Проверяем изменения в занятых местах
      await _checkBookingChanges();
      // Обновляем список активных бронирований
      await _updateActiveBookings();
    } catch (e) {
      print('Ошибка при проверке бронирований: $e');
    }
  }

  Future<void> _checkBookingChanges() async {
    try {
      // Получаем все активные бронирования для отслеживания изменений
      final now = DateTime.now().toUtc();
      final fiveMinAgo = now.subtract(const Duration(minutes: 5));
      final List<dynamic> bookings = await SupabaseService.supabase
          .from('bookings')
          .select()
          .filter('status', 'in', '("pending","confirmed")')
          .gte('booking_time', fiveMinAgo.toIso8601String());
      // Группируем по screeningId для отслеживания изменений
      final Map<int, List<Map<String, dynamic>>> bookingsByScreening = {};
      for (final booking in bookings) {
        final screeningId = booking['screening_id'] as int;
        bookingsByScreening.putIfAbsent(screeningId, () => []).add(booking);
      }

      // Уведомляем о изменениях в каждом сеансе
      for (final screeningId in bookingsByScreening.keys) {
        bookingChangedController.add(
          screeningId,
        ); // Используем тот же контроллер для уведомлений об изменениях
      }
    } catch (e) {
      print('Ошибка при проверке изменений бронирований: $e');
    }
  }

  Future<void> _updateActiveBookings() async {
    try {
      final userId = await SupabaseService.getDeviceId();
      final List<dynamic> bookings = await SupabaseService.supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending');

      _activeBookings.clear();
      for (final booking in bookings) {
        final screeningId = booking['screening_id'] as int;
        final bookingTime = DateTime.tryParse(booking['booking_time'] ?? '');
        if (bookingTime != null) {
          _activeBookings[screeningId] = bookingTime;
        }
      }
    } catch (e) {
      print('Ошибка при обновлении активных бронирований: $e');
    }
  }

  // Добавить бронирование в отслеживание
  void addBooking(int screeningId, DateTime bookingTime) {
    _activeBookings[screeningId] = bookingTime;
  }

  // Удалить бронирование из отслеживания
  void removeBooking(int screeningId) {
    _activeBookings.remove(screeningId);
  }

  void _tick() {
    if (value == null) return;
    final remaining = value!.endTime.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      stop();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
}

class BookingTimerState {
  final String movieTitle;
  final DateTime endTime;
  BookingTimerState({required this.movieTitle, required this.endTime});
}

final bookingTimerController = BookingTimerController();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mooon Cinema',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111114),
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.deepPurpleAccent,
          background: const Color(0xFF111114),
        ),
        fontFamily:
            'SF Pro Display', // Можно заменить на вашу, если потребуется
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: MainScreen(key: mainScreenKey),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ValueListenableBuilder<BookingTimerState?>(
          valueListenable: bookingTimerController,
          builder: (context, state, _) {
            final remaining =
                state?.endTime.difference(DateTime.now()) ?? Duration.zero;
            final showHeader = state != null && remaining > Duration.zero;
            if (!showHeader) return child!;
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                BookingTimerHeader(
                  movieTitle: state.movieTitle,
                  remaining: remaining,
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: child!,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Home по умолчанию

  final List<Widget> _screens = [
    const HomeScreen(),
    const AfishaScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF18181C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Афиша'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

class BookingTimerHeader extends StatelessWidget {
  final String movieTitle;
  final Duration remaining;
  const BookingTimerHeader({
    super.key,
    required this.movieTitle,
    required this.remaining,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 8;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 10),
          color: Colors.black.withOpacity(0.85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                movieTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _format(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
