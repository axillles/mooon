import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/image_service.dart';
import 'session_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailScreen({required this.movie, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 260,
                    child:
                        movie.trailerUrl.isNotEmpty &&
                                YoutubePlayer.convertUrlToId(
                                      movie.trailerUrl,
                                    ) !=
                                    null
                            ? YoutubePlayer(
                              controller: YoutubePlayerController(
                                initialVideoId:
                                    YoutubePlayer.convertUrlToId(
                                      movie.trailerUrl,
                                    )!,
                                flags: const YoutubePlayerFlags(
                                  autoPlay: false,
                                  mute: false,
                                ),
                              ),
                              showVideoProgressIndicator: true,
                              width: double.infinity,
                              aspectRatio: 16 / 9,
                            )
                            : ImageService.getImage(
                              movie.imageUrl,
                              width: double.infinity,
                              height: 260,
                            ),
                  ),
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (movie.galleryUrls.isNotEmpty &&
                      (movie.trailerUrl.isEmpty ||
                          YoutubePlayer.convertUrlToId(movie.trailerUrl) ==
                              null))
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(18.0),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            movie.genres.join(' • '),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Builder(
                          builder: (context) {
                            int hours = movie.durationMinutes ~/ 60;
                            int minutes = movie.durationMinutes % 60;
                            String duration =
                                minutes == 0
                                    ? '$hours ч'
                                    : '$hours ч $minutes мин';
                            return Text(
                              duration,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Возраст
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${movie.ageRestriction}+',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Возраст зрителей',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Блок "В кино с ... по ..."
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              String start = '';
                              String end = '';
                              if (movie.showTimes.isNotEmpty) {
                                final sorted = [...movie.showTimes]..sort();
                                final startDate = sorted.first;
                                final endDate = sorted.last;
                                start =
                                    '${startDate.day} ${_monthName(startDate.month)}';
                                end =
                                    '${endDate.day} ${_monthName(endDate.month)}';
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        color: Colors.white54,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          start.isNotEmpty
                                              ? 'В кино с $start'
                                              : '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          softWrap: true,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (end.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 36),
                                      child: Text(
                                        'по $end',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        softWrap: true,
                                        maxLines: 2,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Информация в две колонки
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DetailInfoColumn(
                            label: 'Жанры:',
                            value: movie.genres.join(', '),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DetailInfoColumn(
                            label: 'Режиссёр:',
                            value: movie.director,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _DetailInfoColumn(
                            label: 'В ролях:',
                            value: movie.movieCast,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: _DetailInfoColumn(
                            label: 'Технологии:',
                            value: movie.technologies.join(', '),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Описание:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.description,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 16,
                      ),
                    ),

                    if (movie.galleryUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Кадры из фильма:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: movie.galleryUrls.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder:
                              (context, index) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImageService.getImage(
                                  movie.galleryUrls[index],
                                  width: 180,
                                  height: 120,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SessionPicker(movie: movie),
              );
            },
            child: const Text(
              'Купить билет',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailInfoColumn extends StatelessWidget {
  final String label;
  final String value;
  const _DetailInfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFCCCCCC),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

String _monthName(int month) {
  const months = [
    '',
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return months[month];
}
