import 'package:flutter/material.dart';
import 'dart:math';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'user_qr_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final int initialTabIndex;
  const ProfileScreen({super.key, this.initialTabIndex = 0});

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

  // Удаляем старые переменные:
  // final double progress = 0.05; // 5%
  // final int userPoints = 500; // Текущее количество баллов пользователя
  // final int goalPoints = 10000; // Цель для перехода на 10%

  int _profileContentIndex = 0; // 0 for info, 1 for password

  // Новые переменные для баллов
  int? allTimePoints;
  int goalPoints = 10000;
  String get cashbackPercent =>
      (allTimePoints ?? 0) >= goalPoints ? '10%' : '5%';
  double get progress =>
      (allTimePoints ?? 0) >= goalPoints
          ? 1.0
          : (allTimePoints ?? 0) / goalPoints;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _loadProfilePoints();
  }

  Future<void> _loadProfilePoints() async {
    final profile = await SupabaseService.getUserProfile();
    setState(() {
      allTimePoints = profile?['all_time_points'] ?? 0;
    });
  }

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
                        child: GestureDetector(
                          onTap: () => showUserQRBottomSheet(context),
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
                                cashbackPercent,
                                style: const TextStyle(
                                  color: Color(0xFF5B5BFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  goalPoints.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Переход на 10%',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Прогресс-бар
                        SizedBox(
                          height: 38,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final barWidth = constraints.maxWidth;
                              final dotPosition =
                                  barWidth * progress.clamp(0.0, 1.0);
                              return Stack(
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
                                        dotPosition -
                                        9, // 9 = половина ширины точки
                                    bottom: 0,
                                    child: Column(
                                      children: [
                                        Text(
                                          (allTimePoints ?? 0).toString(),
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
                              );
                            },
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
            // Контент вкладки
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 1) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getActiveUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                'У вас нет активных билетов',
                style: TextStyle(color: Colors.white38, fontSize: 20),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              final t = tickets[i];
              final movie = t['movie'];
              final screening = t['screening'];
              final hall = t['hall'];
              final cinema = t['cinema'];
              final booking = t['booking'];
              final startTime = DateTime.parse(screening['start_time']);
              final seats = (booking['seats'] as List?)?.join(', ') ?? '';
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
                          DateFormat('d MMMM, HH:mm', 'ru').format(startTime),
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
      );
    } else if (_selectedTab == 3) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getUserBookingHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                'История пуста',
                style: TextStyle(color: Colors.white38, fontSize: 20),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              final t = tickets[i];
              final movie = t['movie'];
              final screening = t['screening'];
              final hall = t['hall'];
              final cinema = t['cinema'];
              final booking = t['booking'];
              final startTime = DateTime.parse(screening['start_time']);
              final seats = (booking['seats'] as List?)?.join(', ') ?? '';
              return FutureBuilder<double>(
                future: () async {
                  double total = 0.0;
                  final seatTypes =
                      (t['seatTypes'] as List?)?.cast<Map<String, dynamic>>() ??
                      [];
                  if (hall != null &&
                      booking['seats'] is List &&
                      seatTypes.isNotEmpty) {
                    final seatsList = booking['seats'] as List;
                    final seatsData = await SupabaseService.supabase
                        .from('seats')
                        .select()
                        .eq('hall_id', hall['id']);
                    for (final seatKey in seatsList) {
                      final parts = seatKey.toString().split('-');
                      if (parts.length == 2) {
                        final row = parts[0].replaceFirst(RegExp(r'^0+'), '');
                        final number = int.tryParse(parts[1]);
                        final seat = (seatsData as List).firstWhere(
                          (s) =>
                              s['row_number'].toString().replaceFirst(
                                    RegExp(r'^0+'),
                                    '',
                                  ) ==
                                  row &&
                              s['seat_number'] == number,
                          orElse: () => {},
                        );
                        if (seat.isNotEmpty) {
                          final typeId = seat['seat_type_id'];
                          final type = seatTypes.firstWhere(
                            (t) => t['id'] == typeId,
                            orElse: () => {},
                          );
                          if (type.isNotEmpty && type['price'] is num) {
                            total += (type['price'] as num).toDouble();
                          }
                        }
                      }
                    }
                  }
                  return total;
                }(),
                builder: (context, snap) {
                  final total = snap.data ?? 0.0;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF23232A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                movie?['title'] ?? 'Фильм',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                total > 0
                                    ? '${total.toStringAsFixed(2).replaceAll('.', ',')} BYN'
                                    : '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
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
          );
        },
      );
    } else if (_selectedTab == 4) {
      return _buildProfileTab();
    } else if (_selectedTab == 0) {
      // Домой: объяснение партнерской программы
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ваш уровень лояльности 5%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 370,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _LoyaltyCard(
                      percent: '5%',
                      title: 'товары и билеты',
                      description:
                          'Все новые участники программы лояльности попадают на уровень 5% и могут получать бонусами до 5% от суммы покупок',
                    ),
                    const SizedBox(width: 18),
                    _LoyaltyCard(
                      percent: '10%',
                      title: 'товары и билеты',
                      description:
                          'Участники с уровнем лояльности 5%, накопившие 10 000 бонусов, автоматически попадают на уровень 10% и могут получать бонусами до 10% от суммы покупок',
                    ),
                    const SizedBox(width: 18),
                    _LoyaltyCard(
                      percent: '1 BYN = 100',
                      title: '',
                      description:
                          'Бонусы начисляются на следующий день после приобретения товара или получения услуги',
                      isByn: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // YouTube video section
              LoyaltyYoutubePlayer(),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child:
            _selectedTab == 0
                ? const Icon(Icons.home, color: Colors.white38, size: 60)
                : Text(
                  _tabs[_selectedTab],
                  style: const TextStyle(color: Colors.white38, fontSize: 22),
                ),
      );
    }
  }

  Widget _buildProfileTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(child: _buildSubTabButton('Профиль', 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildSubTabButton('Пароль', 1)),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _profileContentIndex,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  const SizedBox(height: 8),
                  const ProfileInfoEditor(),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: const Color(0xFF23232A),
                              title: const Text(
                                'Удалить аккаунт?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Вы уверены, что хотите удалить аккаунт? Это действие необратимо.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Удалить',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        try {
                          await SupabaseService.supabase.auth.admin.deleteUser(
                            SupabaseService.supabase.auth.currentUser!.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Письмо для подтверждения удаления отправлено.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      'Удалить мой профиль',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Вы получите электронное письмо для подтверждения вашего решения.\n\nПосле подтверждения ваш профиль на сайте mooon.by будет удалён. Все начисленные и неиспользованные бонусы по программе лояльности будут аннулированы. Восстановить личный кабинет и данные в нем невозможно.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const PasswordEditor(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String text, int index) {
    final isSelected = _profileContentIndex == index;
    return ElevatedButton(
      onPressed: () => setState(() => _profileContentIndex = index),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF5B5BFF) : const Color(0xFF23232A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class ProfileInfoEditor extends StatefulWidget {
  const ProfileInfoEditor({Key? key}) : super(key: key);

  @override
  State<ProfileInfoEditor> createState() => _ProfileInfoEditorState();
}

class _ProfileInfoEditorState extends State<ProfileInfoEditor> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await SupabaseService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _editField(
    BuildContext context,
    String fieldKey,
    String label, {
    bool isDate = false,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: _userProfile?[fieldKey] ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF23232A),
            title: Text(
              'Изменить ${label.toLowerCase()}',
              style: const TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white38),
              ),
              keyboardType:
                  isDate ? TextInputType.datetime : TextInputType.text,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Сохранить'),
              ),
            ],
          ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.updateUserProfile({fieldKey: result.trim()});
      } catch (e) {
        // Handle error
      } finally {
        await _loadUserProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userProfile == null) {
      return const Center(
        child: Text(
          'Войдите, чтобы редактировать профиль',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _ProfileInfoTile(
            label: 'Фамилия',
            value: _userProfile?['last_name'],
            onEdit: () => _editField(context, 'last_name', 'Фамилия'),
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            label: 'Имя',
            value: _userProfile?['first_name'],
            onEdit: () => _editField(context, 'first_name', 'Имя'),
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            label: 'Дата рождения',
            value: _userProfile?['birth_date'],
            onEdit:
                () => _editField(
                  context,
                  'birth_date',
                  'Дата рождения',
                  isDate: true,
                ),
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            label: 'Email',
            value: _userProfile?['email'],
            onEdit: () {}, // Email editing is usually more complex
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            label: 'Телефон',
            value: _userProfile?['phone'],
            onEdit: () => _editField(context, 'phone', 'Телефон'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onEdit;

  const _ProfileInfoTile({
    required this.label,
    this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value != null && value!.isNotEmpty ? value! : '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (label != 'Email')
            TextButton(
              onPressed: onEdit,
              child: const Text(
                'изменить',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class PasswordEditor extends StatefulWidget {
  const PasswordEditor({Key? key}) : super(key: key);

  @override
  State<PasswordEditor> createState() => _PasswordEditorState();
}

class _PasswordEditorState extends State<PasswordEditor> {
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _changePassword() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.updateUserPassword(_newPasswordController.text);
        setState(() => _successMessage = 'Пароль успешно изменен!');
        _newPasswordController.clear();
        _repeatPasswordController.clear();
      } catch (e) {
        setState(() => _errorMessage = 'Ошибка: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Новый пароль',
              labelStyle: TextStyle(color: Colors.white54),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Пароль должен быть не менее 6 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _repeatPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Повторите пароль',
              labelStyle: TextStyle(color: Colors.white54),
            ),
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            child:
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
          ),
        ],
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

class _LoyaltyCard extends StatelessWidget {
  final String percent;
  final String title;
  final String description;
  final bool isByn;
  const _LoyaltyCard({
    required this.percent,
    required this.title,
    required this.description,
    this.isByn = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isByn) ...[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                percent,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
            ] else ...[
              Icon(Icons.sync, color: Color(0xFF5B5BFF), size: 44),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF5B5BFF), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percent,
                  style: const TextStyle(
                    color: Color(0xFF5B5BFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// YouTube player widget for loyalty tab
class LoyaltyYoutubePlayer extends StatefulWidget {
  const LoyaltyYoutubePlayer({Key? key}) : super(key: key);

  @override
  State<LoyaltyYoutubePlayer> createState() => _LoyaltyYoutubePlayerState();
}

class _LoyaltyYoutubePlayerState extends State<LoyaltyYoutubePlayer> {
  late YoutubePlayerController _controller;
  final String videoId =
      YoutubePlayer.convertUrlToId(
        // Вставь сюда свою ссылку на видео
        'https://www.youtube.com/watch?v=vXeW1qd7B7U&t=105s',
      )!;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          width: double.infinity,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
