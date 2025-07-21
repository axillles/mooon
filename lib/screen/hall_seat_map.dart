import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/filters.dart';
import 'dart:math';

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
    final minX = seats.map((s) => s.x).reduce(min);
    final maxX = seats.map((s) => s.x).reduce(max);
    final minY = seats.map((s) => s.y).reduce(min);
    final maxY = seats.map((s) => s.y).reduce(max);
    final width = maxX - minX;
    final height = maxY - minY;
    final rows = <String, List<Seat>>{};
    for (final seat in seats) {
      rows.putIfAbsent(seat.rowNumber, () => []).add(seat);
    }
    final doubleSeatScale = 1.7;
    final labelWidth = 32.0;
    final hGapRatio = 0.05;
    final vGapRatio = 0.22;
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
        final seatSizeW = availableWidth / maxRowWidth;
        final seatSizeH =
            availableHeight / (rowCount + vGapRatio * (rowCount - 1));
        final seatSize = seatSizeW < seatSizeH ? seatSizeW : seatSizeH;
        final hGap = seatSize * hGapRatio;
        final vGap = seatSize * vGapRatio;
        final totalWidth = maxRowWidth * seatSize;
        final totalHeight = rowCount * seatSize + (rowCount - 1) * vGap;
        final offsetX = (constraints.maxWidth - totalWidth) / 2;
        final offsetY = 80 + padding;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SizedBox(height: 60, child: GlowingScreen()),
            ),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            child: SvgPicture.asset(asset, color: color),
                          ),
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
              return Stack(
                children: [
                  Positioned(
                    left: offsetX - labelWidth,
                    top: offsetY + rowIdx * (seatSize + vGap) + seatSize / 4,
                    child: _RowLabel(row: row),
                  ),
                  Positioned(
                    left: offsetX + totalWidth + 4,
                    top: offsetY + rowIdx * (seatSize + vGap) + seatSize / 4,
                    child: _RowLabel(row: row),
                  ),
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
