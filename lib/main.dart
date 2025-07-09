import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'screen/afisha_screen.dart';
import 'screen/profile_screen.dart';
import 'services/supabase_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await initializeDateFormatting('ru', null);
  runApp(const MyApp());
}

// Глобальный контроллер таймера бронирования
class BookingTimerController extends ValueNotifier<BookingTimerState?> {
  BookingTimerController() : super(null);

  Timer? _timer;

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
  }

  void stop() {
    _timer?.cancel();
    value = null;
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
      home: const MainScreen(),
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
                  movieTitle: state!.movieTitle,
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
  int _selectedIndex = 1; // Афиша по умолчанию

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
