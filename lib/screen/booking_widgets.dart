import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/filters.dart';
import 'dart:ui';

class Tag extends StatelessWidget {
  final String text;
  const Tag({required this.text});
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

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;
  const InfoCard({
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

class SeatTypesLegend extends StatelessWidget {
  final List<Seat> seats;
  final List<SeatType> seatTypes;
  const SeatTypesLegend({required this.seats, required this.seatTypes});

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
                SeatTypeRow(type: usedTypes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SeatTypeRow extends StatefulWidget {
  final SeatType type;
  const SeatTypeRow({required this.type});

  @override
  State<SeatTypeRow> createState() => SeatTypeRowState();
}

class SeatTypeRowState extends State<SeatTypeRow> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    String asset;
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

class SeatStatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        StatusBox(color: Color(0xFF6B7AFF), label: 'Свободно'),
        const SizedBox(width: 18),
        StatusBox(color: Color(0xFF44464F), label: 'Занято'),
      ],
    );
  }
}

class StatusBox extends StatelessWidget {
  final Color color;
  final String label;
  const StatusBox({required this.color, required this.label});

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

class BookingTimerHeader extends StatelessWidget {
  final String movieTitle;
  final int secondsLeft;
  const BookingTimerHeader({
    required this.movieTitle,
    required this.secondsLeft,
  });

  String get timerString {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              border: const Border(
                bottom: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  movieTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timerString,
                  style: const TextStyle(
                    color: Color(0xFF6B7AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExtendTimeDialog extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onExtend;
  const ExtendTimeDialog({required this.onClose, required this.onExtend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF23232A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Осталось мало времени',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Через минуту ваш сеанс\nбронирования будет завершен',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.3,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onExtend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B7AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Добавить 5 мин',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
