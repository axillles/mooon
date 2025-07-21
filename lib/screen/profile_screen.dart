import 'package:flutter/material.dart';
import 'dart:math';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    '', // Домой (иконка)
    'Мои билеты',
    'Сертификаты',
    'История',
    'Профиль',
  ];

  // Пример прогресса (0.0 - 1.0)
  final double progress = 0.05; // 5%
  final int userPoints = 500; // Текущее количество баллов пользователя
  final int goalPoints = 10000; // Цель для перехода на 10%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть: аватар, имя, прогресс, баланс
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Аватар с прогресс-баром и QR
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF23232A),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white38,
                          size: 54,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Имя и прогресс
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Артем Гаврилов',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Цель и процент
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFF5B5BFF)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xFF5B5BFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              goalPoints.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Переход на 10%',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        // Прогресс-бар
                        SizedBox(
                          height: 38,
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              // Фоновая линия
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Прогресс
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B5BFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              // Точка и баллы пользователя
                              Positioned(
                                left:
                                    (MediaQuery.of(context).size.width - 120) *
                                    progress.clamp(0.0, 1.0),
                                bottom: 0,
                                child: Column(
                                  children: [
                                    Text(
                                      userPoints.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF5B5BFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color(0xFF5B5BFF),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Вкладки
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    if (i == 0) {
                      // Домой вкладка
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.home,
                              color:
                                  selected
                                      ? const Color(0xFF23232A)
                                      : Colors.white54,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Остальные вкладки
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? const Color(0xFF5B5BFF)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Контент вкладки (пока просто заглушка)
            Expanded(
              child:
                  _selectedTab == 1
                      ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: SupabaseService.getActiveUserBookings(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final tickets = snapshot.data ?? [];
                          if (tickets.isEmpty) {
                            return const Center(
                              child: Text(
                                'У вас нет активных билетов',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 20,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            itemCount: tickets.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, i) {
                              final t = tickets[i];
                              final movie = t['movie'];
                              final screening = t['screening'];
                              final hall = t['hall'];
                              final cinema = t['cinema'];
                              final booking = t['booking'];
                              final startTime = DateTime.parse(
                                screening['start_time'],
                              );
                              final seats =
                                  (booking['seats'] as List?)?.join(', ') ?? '';
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF23232A),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie?['title'] ?? 'Фильм',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.event,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat(
                                            'd MMMM, HH:mm',
                                            'ru',
                                          ).format(startTime),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.chair,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Места: $seats',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${cinema?['name'] ?? ''}, ${cinema?['address'] ?? ''}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.meeting_room,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Зал: ${hall?['name'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      )
                      : Center(
                        child:
                            _selectedTab == 0
                                ? const Icon(
                                  Icons.home,
                                  color: Colors.white38,
                                  size: 60,
                                )
                                : Text(
                                  _tabs[_selectedTab],
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 22,
                                  ),
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarProgressPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  AvatarProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final avatarRadius = 30.0; // радиус аватарки (60/2)
    final gap = 10.0; // расстояние между аватаркой и прогресс-баром
    final radius = avatarRadius + gap + 10.0 / 2; // радиус прогресс-бара
    final strokeWidth = 10.0;
    final startAngle = 1.5 * pi; // 270°, строго снизу
    final sweepAngle = 2 * pi; // полный круг
    final progressAngle = sweepAngle * progress;

    // Фоновый круг
    final bgPaint =
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      sweepAngle,
      false,
      bgPaint,
    );

    // Прогресс-дуга
    final progressPaint =
        Paint()
          ..color = const Color(0xFF5B5BFF)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );

    // Синяя точка (старт, строго снизу)
    final startDotAngle = startAngle;
    final startDotOffset = Offset(
      center.dx + radius * cos(startDotAngle),
      center.dy + radius * sin(startDotAngle),
    );
    final blueDotPaint = Paint()..color = const Color(0xFF5B5BFF);
    canvas.drawCircle(startDotOffset, 5, blueDotPaint);

    // Белая точка (конец прогресса, тоже по кругу)
    final endDotAngle = startAngle + progressAngle;
    final endDotOffset = Offset(
      center.dx + radius * cos(endDotAngle),
      center.dy + radius * sin(endDotAngle),
    );
    final whiteDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(endDotOffset, 4, whiteDotPaint);
  }

  @override
  bool shouldRepaint(covariant AvatarProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
