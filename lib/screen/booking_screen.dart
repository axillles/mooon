import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/movie.dart';
import '../models/filters.dart';

class BookingScreen extends StatelessWidget {
  final Movie movie;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName;
  final DateTime date;
  final String time;

  const BookingScreen({
    Key? key,
    required this.movie,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final genres = movie.genres.isNotEmpty ? movie.genres.first : '';
    final duration =
        '${movie.durationMinutes ~/ 60} ч ${movie.durationMinutes % 60} мин';
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Постер и описание
              Stack(
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: Image.network(movie.imageUrl, fit: BoxFit.cover),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
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
                        _Tag(text: '${movie.ageRestriction}+'),
                        if (movie.languages.isNotEmpty)
                          _Tag(text: movie.languages.first),
                        if (movie.technologies.isNotEmpty)
                          _Tag(text: movie.technologies.first),
                        if (movie.technologies.length > 1)
                          _Tag(text: movie.technologies[1]),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Дата',
                        value: _formatDate(date),
                        borderRadius: BorderRadius.circular(16),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    ),
                    Expanded(
                      child: _InfoCard(
                        title: 'Сеанс',
                        value: time,
                        borderRadius: BorderRadius.circular(16),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                    Expanded(
                      child: _InfoCard(
                        title: 'Зал',
                        value: hallName,
                        borderRadius: BorderRadius.circular(16),
                        margin: const EdgeInsets.only(left: 8),
                      ),
                    ),
                  ],
                ),
              ),
              // Пространство
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Пространство',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cinemaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cinemaAddress,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Виртуальный зал
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                child: Center(
                  child: Column(
                    children: [
                      GlowingScreen(),
                      const SizedBox(height: 8),
                      CinemaHallView(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;
  const _InfoCard({
    required this.title,
    required this.value,
    required this.borderRadius,
    this.margin,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.white24.withOpacity(0.35), width: 2),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: 0.18,
            child: Container(height: 1.2, width: 60, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class CinemaHallView extends StatefulWidget {
  const CinemaHallView({Key? key}) : super(key: key);

  @override
  State<CinemaHallView> createState() => _CinemaHallViewState();
}

class _CinemaHallViewState extends State<CinemaHallView> {
  static const int rows = 7;
  static const int cols = 10;

  List<List<bool>> takenSeats = List.generate(7, (i) => List.filled(10, false));
  Set<String> selectedSeats = {};

  @override
  void initState() {
    super.initState();
    takenSeats[0][2] = true;
    takenSeats[0][3] = true;
    takenSeats[1][5] = true;
    takenSeats[2][0] = true;
    takenSeats[2][1] = true;
    takenSeats[3][0] = true;
    takenSeats[3][5] = true;
    takenSeats[5][7] = true;
    takenSeats[6][9] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows * cols,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          int row = index ~/ cols;
          int col = index % cols;
          bool isTaken = takenSeats[row][col];
          String seatKey = "$row-$col";
          bool isSelected = selectedSeats.contains(seatKey);

          Color seatColor;
          if (isTaken) {
            seatColor = Colors.grey.shade800;
          } else if (isSelected) {
            seatColor = Colors.white;
          } else {
            seatColor = Colors.blueAccent;
          }

          return GestureDetector(
            onTap:
                isTaken
                    ? null
                    : () {
                      setState(() {
                        if (isSelected) {
                          selectedSeats.remove(seatKey);
                        } else {
                          selectedSeats.add(seatKey);
                        }
                      });
                    },
            child: SvgPicture.asset(
              'assets/images/single.svg',
              color: seatColor,
              width: 24,
              height: 24,
            ),
          );
        },
      ),
    );
  }
}

class GlowingScreen extends StatelessWidget {
  const GlowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 1. Твоя PNG-картинка с блюром
        Image.asset(
          'assets/images/blur.png',
          width: double.infinity,
          height: 80,
          fit: BoxFit.cover,
        ),

        // 2. Белая кривая линия сверху
        CustomPaint(
          size: const Size(double.infinity, 60),
          painter: _ScreenCurvePainter(),
        ),
      ],
    );
  }
}

class _ScreenCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6;

    final path = Path();
    final curveHeight = size.height * 0.3;

    path.moveTo(0, curveHeight);
    path.quadraticBezierTo(size.width / 2, 0, size.width, curveHeight);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
