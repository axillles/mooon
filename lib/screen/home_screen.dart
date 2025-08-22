import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/movie.dart';
import '../services/image_service.dart';
import 'movie_detail_screen.dart';
import 'afisha_screen.dart';
import 'user_qr_bottom_sheet.dart';
import 'user_tickets_bottom_sheet.dart';
import 'news_detail_screen.dart';
import '../main.dart' show mainScreenKey;
import 'food_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/images/logo.png',
                    color: Colors.white,
                    height: 40,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showUserQRBottomSheet(context),
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        label: const Text(
                          'QR',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => showUserTicketsBottomSheet(context),
                        icon: const Icon(
                          Icons.confirmation_num_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Билеты',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5BFF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Баннер заказа еды во время сеанса (если доступно)
          const SliverToBoxAdapter(child: _FoodBanner()),
          // Новости
          const SliverToBoxAdapter(child: _NewsSection()),
          // Мини-афиша ближайших сеансов
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'сегодня в кино',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder:
                        (ctx) => TextButton(
                          onPressed: () {
                            // Переход на вкладку Афиша внутри MainScreen
                            if (mainScreenKey.currentState != null) {
                              mainScreenKey.currentState!.switchToTab(1);
                            } else {
                              Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) => const AfishaScreen(),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'вся афиша',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _MiniAfisha()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getActiveNews(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final news = snapshot.data ?? [];
        if (news.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Новостей пока нет',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder:
                    (_, i) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        minWidth: 260,
                      ),
                      child: _NewsItem(news: news[i]),
                    ),
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemCount: news.length,
              ),
            );
          },
        );
      },
    );
  }
}

class _FoodBanner extends StatefulWidget {
  const _FoodBanner();

  @override
  State<_FoodBanner> createState() => _FoodBannerState();
}

class _FoodBannerState extends State<_FoodBanner> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    // Обновляем не чаще, чем раз в 15 секунд
    final now = DateTime.now();
    if (now.difference(_lastFetch).inSeconds < 15 && !_loading) return;
    setState(() => _loading = true);
    final data = await SupabaseService.getCurrentFoodEligibleScreening();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _lastFetch = now;
    });
    // Планируем следующее обновление через 30 секунд
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) return const SizedBox.shrink();
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final movie = data['movie'];
    final hall = data['hall'];
    final screening = data['screening'];
    final booking = data['booking'];
    String? seatRow;
    int? seatNumber;
    try {
      final seats = booking?['seats'];
      if (seats is List && seats.isNotEmpty) {
        final first = seats.first;
        if (first is String && first.contains('-')) {
          final parts = first.split('-');
          if (parts.length == 2) {
            seatRow = parts[0];
            seatNumber = int.tryParse(parts[1]);
          }
        }
      }
    } catch (_) {}
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => FoodMenuScreen(
                    screeningId: screening?['id'] as int?,
                    seatRow: seatRow,
                    seatNumber: seatNumber,
                  ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A34),
            border: Border.all(color: Colors.white12, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.fastfood, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Доступен заказ в зал',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie?['title'] ?? ''} • ${hall?['name'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final Map<String, dynamic> news;
  const _NewsItem({required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(newsId: news['id']),
          ),
        );
      },
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'новости',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                news['title'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    news['subtitle'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'читать',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAfisha extends StatefulWidget {
  @override
  State<_MiniAfisha> createState() => _MiniAfishaState();
}

class _MiniAfishaState extends State<_MiniAfisha> {
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.getMoviesByDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Movie>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Сегодня сеансов нет',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }
        return SizedBox(
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _MiniPoster(movie: movies[i]),
          ),
        );
      },
    );
  }
}

class _MiniPoster extends StatelessWidget {
  final Movie movie;
  const _MiniPoster({required this.movie});

  @override
  Widget build(BuildContext context) {
    final showTimes =
        movie.showTimes
            .where(
              (t) =>
                  DateTime(t.year, t.month, t.day) ==
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
            )
            .toList()
          ..sort();

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
          ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: ImageService.getImage(
                  movie.imageUrl,
                  width: double.infinity,
                  height: 170,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      showTimes.isNotEmpty
                          ? showTimes
                              .take(3)
                              .map((t) => DateFormat('HH:mm').format(t))
                              .join('  ')
                          : '—',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
