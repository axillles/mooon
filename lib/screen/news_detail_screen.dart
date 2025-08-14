import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class NewsDetailScreen extends StatelessWidget {
  final int newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Новость',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: SupabaseService.getNewsById(newsId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final news = snapshot.data;
          if (news == null) {
            return const Center(
              child: Text(
                'Новость не найдена',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Text(
                  news['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Подзаголовок
                if (news['subtitle'] != null) ...[
                  Text(
                    news['subtitle'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Мета-информация
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 20,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mooon',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (news['published_at'] != null) ...[
                      Icon(Icons.access_time, color: Colors.white38, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'd MMMM yyyy',
                          'ru',
                        ).format(DateTime.parse(news['published_at'])),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Изображение (если есть)
                if (news['image_url'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      news['image_url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Содержание
                if (news['content'] != null) ...[
                  Text(
                    news['content'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
