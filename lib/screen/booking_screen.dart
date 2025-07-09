import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/movie.dart';
import '../models/filters.dart';
import '../services/supabase_service.dart';
import 'dart:math';

class BookingScreen extends StatefulWidget {
  final Movie movie;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName;
  final DateTime date;
  final String time;
  final int hallId;

  const BookingScreen({
    Key? key,
    required this.movie,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.date,
    required this.time,
    required this.hallId,
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

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() => isLoading = true);
    final loadedSeats = await SupabaseService.getSeatsByHall(widget.hallId);
    final loadedTypes = await SupabaseService.getSeatTypes();
    setState(() {
      seats = loadedSeats;
      seatTypes = loadedTypes;
      isLoading = false;
    });
  }

  void _onSeatTap(String seatKey) {
    setState(() {
      if (selectedSeats.contains(seatKey)) {
        selectedSeats.remove(seatKey);
      } else {
        selectedSeats.add(seatKey);
      }
    });
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
                    child: Image.network(
                      widget.movie.imageUrl,
                      fit: BoxFit.cover,
                    ),
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
                        _Tag(text: '${widget.movie.ageRestriction}+'),
                        if (widget.movie.languages.isNotEmpty)
                          _Tag(text: widget.movie.languages.first),
                        if (widget.movie.technologies.isNotEmpty)
                          _Tag(text: widget.movie.technologies.first),
                        if (widget.movie.technologies.length > 1)
                          _Tag(text: widget.movie.technologies[1]),
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
                        value: _formatDate(widget.date),
                        borderRadius: BorderRadius.circular(16),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    ),
                    Expanded(
                      child: _InfoCard(
                        title: 'Сеанс',
                        value: widget.time,
                        borderRadius: BorderRadius.circular(16),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                    Expanded(
                      child: _InfoCard(
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
              // Сноска "Статус мест"
              if (!isLoading && seats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 18,
                  ),
                  child: _SeatStatusLegend(),
                ),
              // Сноска "Типы мест"
              if (!isLoading && seats.isNotEmpty && seatTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _SeatTypesLegend(seats: seats, seatTypes: seatTypes),
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
      height: 110,
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
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HallSeatMap extends StatelessWidget {
  final List<Seat> seats;
  final List<SeatType> seatTypes;
  final Set<String> selectedSeats;
  final Set<String> takenSeats;
  final void Function(String seatKey)? onSeatTap;

  const HallSeatMap({
    Key? key,
    required this.seats,
    required this.seatTypes,
    this.selectedSeats = const {},
    this.takenSeats = const {},
    this.onSeatTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const Center(child: Text('Нет данных о рассадке'));
    }
    // 1. Границы рассадки
    final minX = seats.map((s) => s.x).reduce(min);
    final maxX = seats.map((s) => s.x).reduce(max);
    final minY = seats.map((s) => s.y).reduce(min);
    final maxY = seats.map((s) => s.y).reduce(max);
    final width = maxX - minX;
    final height = maxY - minY;

    // 2. Группировка по рядам для подписей и вычисление максимальной ширины ряда
    final rows = <String, List<Seat>>{};
    for (final seat in seats) {
      rows.putIfAbsent(seat.rowNumber, () => []).add(seat);
    }
    final double doubleSeatScale = 1.7;
    final labelWidth = 32.0;
    final hGapRatio = 0.05; // горизонтальный gap стал меньше
    final vGapRatio = 0.22; // вертикальный gap
    double getSeatWidth(SeatType type) {
      switch (type.code) {
        case 'loveseat':
        case 'sofa':
        case 'recliner':
        case 'loveseatrecliner':
        case 'love_seat_recliner':
          return doubleSeatScale;
        default:
          return 1.0;
      }
    }

    double maxRowWidth = 0;
    for (final rowSeats in rows.values) {
      double rowWidth = 0;
      for (final seat in rowSeats) {
        final type = seatTypes.firstWhere(
          (t) => t.id == seat.seatTypeId,
          orElse: () => seatTypes.first,
        );
        rowWidth += getSeatWidth(type);
      }
      // Добавляем gap между креслами (кол-во кресел - 1)
      if (rowSeats.length > 1) {
        rowWidth += hGapRatio * (rowSeats.length - 1);
      }
      maxRowWidth = max(maxRowWidth, rowWidth);
    }
    final rowCount = rows.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = 8.0;
        final availableWidth =
            constraints.maxWidth - 2 * (labelWidth + padding);
        final availableHeight = constraints.maxHeight - 60 - padding * 2;
        // seatSize с учётом gap'ов
        final seatSizeW = availableWidth / maxRowWidth;
        final seatSizeH =
            availableHeight / (rowCount + vGapRatio * (rowCount - 1));
        final seatSize = seatSizeW < seatSizeH ? seatSizeW : seatSizeH;
        final hGap = seatSize * hGapRatio;
        final vGap = seatSize * vGapRatio;
        final totalWidth = maxRowWidth * seatSize;
        final totalHeight = rowCount * seatSize + (rowCount - 1) * vGap;
        final offsetX = (constraints.maxWidth - totalWidth) / 2;
        final offsetY = 80 + padding; // теперь кресла ближе к экрану
        return Stack(
          children: [
            // Экран (GlowingScreen) сверху
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SizedBox(height: 60, child: GlowingScreen()),
            ),
            // Кресла и подписи рядов
            ...rows.entries.mapIndexed((rowIdx, entry) {
              final row = entry.key;
              final seatsInRow = [...entry.value]
                ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
              double xCursor = 0;
              List<Widget> seatWidgets = [];
              for (int i = 0; i < seatsInRow.length; i++) {
                final seat = seatsInRow[i];
                final seatType = seatTypes.firstWhere(
                  (t) => t.id == seat.seatTypeId,
                  orElse: () => seatTypes.first,
                );
                final seatKey = '${seat.rowNumber}-${seat.seatNumber}';
                final isSelected = selectedSeats.contains(seatKey);
                final isTaken = takenSeats.contains(seatKey);
                String asset;
                double widthFactor = getSeatWidth(seatType);
                switch (seatType.code) {
                  case 'loveseat':
                  case 'sofa':
                  case 'recliner':
                  case 'loveseatrecliner':
                  case 'love_seat_recliner':
                    asset =
                        'assets/images/' +
                        (seatType.code == 'sofa'
                            ? 'sofa'
                            : seatType.code == 'loveseat'
                            ? 'loveseat'
                            : seatType.code == 'recliner'
                            ? 'recliner'
                            : 'loveSeatRecliner') +
                        '.svg';
                    break;
                  default:
                    asset = 'assets/images/single.svg';
                }
                Color color;
                if (isTaken) {
                  color = Colors.grey.shade800;
                } else if (isSelected) {
                  color = Colors.white;
                } else {
                  color = Colors.blueAccent;
                }
                final seatWidth = seatSize * widthFactor;
                seatWidgets.add(
                  Positioned(
                    left: offsetX + xCursor,
                    top: offsetY + rowIdx * (seatSize + vGap),
                    child: Transform.rotate(
                      angle: seat.angle * 3.1415926 / 180,
                      child: GestureDetector(
                        onTap: isTaken ? null : () => onSeatTap?.call(seatKey),
                        child: SizedBox(
                          width: seatWidth,
                          height: seatSize,
                          child: SvgPicture.asset(asset, color: color),
                        ),
                      ),
                    ),
                  ),
                );
                xCursor += seatWidth;
                if (i < seatsInRow.length - 1) {
                  xCursor += hGap;
                }
              }
              // Подписи рядов слева и справа
              return Stack(
                children: [
                  // Слева
                  Positioned(
                    left: offsetX - labelWidth,
                    top: offsetY + rowIdx * (seatSize + vGap) + seatSize / 4,
                    child: _RowLabel(row: row),
                  ),
                  // Справа
                  Positioned(
                    left: offsetX + totalWidth + 4,
                    top: offsetY + rowIdx * (seatSize + vGap) + seatSize / 4,
                    child: _RowLabel(row: row),
                  ),
                  // Кресла
                  ...seatWidgets,
                ],
              );
            }),
          ],
        );
      },
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
        Image.asset(
          'assets/images/blur.png',
          width: double.infinity,
          height: 80,
          fit: BoxFit.cover,
        ),
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

class _RowLabel extends StatelessWidget {
  final String row;
  const _RowLabel({required this.row});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF23232A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: Text(
        row,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Для mapIndexed
extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}

class _SeatTypesLegend extends StatelessWidget {
  final List<Seat> seats;
  final List<SeatType> seatTypes;
  const _SeatTypesLegend({required this.seats, required this.seatTypes});

  @override
  Widget build(BuildContext context) {
    final usedTypeIds = seats.map((s) => s.seatTypeId).toSet();
    final usedTypes =
        seatTypes.where((t) => usedTypeIds.contains(t.id)).toList();
    usedTypes.sort((a, b) => a.name.compareTo(b.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 18, top: 8),
          child: Text(
            'Типы мест',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF19191C), Color(0xFF111114)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (int i = 0; i < usedTypes.length; i++) ...[
                if (i > 0)
                  const Divider(
                    color: Colors.white12,
                    height: 1,
                    thickness: 1,
                    indent: 24,
                    endIndent: 24,
                  ),
                _SeatTypeRow(type: usedTypes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SeatTypeRow extends StatefulWidget {
  final SeatType type;
  const _SeatTypeRow({required this.type});

  @override
  State<_SeatTypeRow> createState() => _SeatTypeRowState();
}

class _SeatTypeRowState extends State<_SeatTypeRow> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    String asset;
    // Цвет иконки зависит от expanded
    Color iconColor = expanded ? Colors.white : const Color(0xFF6B7AFF);
    switch (type.code) {
      case 'loveseat':
        asset = 'assets/images/loveseat.svg';
        break;
      case 'sofa':
        asset = 'assets/images/sofa.svg';
        break;
      case 'recliner':
        asset = 'assets/images/recliner.svg';
        break;
      case 'loveseatrecliner':
      case 'love_seat_recliner':
        asset = 'assets/images/loveSeatRecliner.svg';
        break;
      default:
        asset = 'assets/images/single.svg';
    }
    String price = '-';
    if (type.price != null) {
      price = type.price!.toStringAsFixed(2).replaceAll('.', ',') + ' BYN';
    }
    // Градиент для карточки и описания
    final BoxDecoration cardDecoration = BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF19191C), Color(0xFF111114)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius:
          expanded
              ? const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              )
              : BorderRadius.circular(18),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => expanded = !expanded),
          child: Container(
            height: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: cardDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  asset,
                  color: iconColor,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    type.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 18),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white24, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild:
              type.description != null && type.description!.isNotEmpty
                  ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 8,
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF19191C), Color(0xFF111114)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      type.description!,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

// Легенда "Свободно/Занято"
class _SeatStatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _StatusBox(color: Color(0xFF6B7AFF), label: 'Свободно'),
        const SizedBox(width: 18),
        _StatusBox(color: Color(0xFF44464F), label: 'Занято'),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
