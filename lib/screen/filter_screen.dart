import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Даты
  final DateTime today = DateTime.now();
  late List<DateTime> weekDates;
  int selectedDateIndex = 0;

  // Время
  RangeValues timeRange = const RangeValues(0, 24);

  // Города и пространства
  String selectedCity = 'Минск';
  final List<String> cities = ['Минск', 'Гомель', 'Брест'];
  int selectedSpaceIndex = 0;
  final List<Map<String, String>> spaces = [
    {
      'name': 'mooon в ТРЦ "Dana Mall"',
      'address': 'г.Минск, ул. Петра Мстиславца, 11 (ТРЦ Dana Mall, 3 этаж)',
    },
    {
      'name': 'Silver Screen в ТРЦ "Arena City"',
      'address': 'г.Минск, пр-т Победителей, 84 (ТРЦ Arena City, 2-4 этаж)',
    },
    {
      'name': 'mooon в ТРЦ "Palazzo"',
      'address': 'г.Минск, ул. Тимирязева, 74а (ТРЦ Palazzo, 3 этаж)',
    },
  ];

  // Залы, технологии, языки, жанры
  final List<String> halls = ['Kids', 'Vip', 'Vegas', 'Resto', 'IMAX'];
  final List<String> technologies = ['2D', '3D', 'DD', '4K'];
  final List<String> languages = ['OV', 'EN', 'RU'];
  final List<String> genres = [
    'семейный',
    'мультфильм',
    'боевик',
    'триллер',
    'драма',
    'фэнтези',
    'ужасы',
    'фантастика',
    'приключения',
    'криминал',
    'детектив',
    'история',
    'спорт',
    'мелодрама',
    'комедия',
    'биография',
    'мюзикл',
    'спектакль',
    'фестиваль',
    'лекция',
    'балет',
    'опера',
    'музыка',
  ];
  final Set<String> selectedHalls = {};
  final Set<String> selectedTechnologies = {};
  final Set<String> selectedLanguages = {};
  final Set<String> selectedGenres = {};

  @override
  void initState() {
    super.initState();
    weekDates = List.generate(8, (i) => today.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        elevation: 0,
        title: const Text(
          'Фильтр',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: selectedCity,
              dropdownColor: const Color(0xFF18181C),
              underline: const SizedBox(),
              icon: const Icon(Icons.location_on, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              items:
                  cities
                      .map(
                        (city) =>
                            DropdownMenuItem(value: city, child: Text(city)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedCity = value);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Даты
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weekDates.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == weekDates.length) {
                  return _CalendarButton();
                }
                final date = weekDates[i];
                final isSelected = selectedDateIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => selectedDateIndex = i),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF5B5BFF)
                              : const Color(0xFF18181C),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          isSelected
                              ? Border.all(
                                color: const Color(0xFF5B5BFF),
                                width: 2,
                              )
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E('ru').format(date).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          i == 0
                              ? 'сегодня'
                              : DateFormat.MMM('ru').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Время
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Время:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Выбранный период: ${_formatTime(timeRange.start)} - ${_formatTime(timeRange.end)}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: const Color(0xFF5B5BFF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF5B5BFF),
              overlayColor: Colors.white24,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
            ),
            child: RangeSlider(
              min: 0,
              max: 24,
              divisions: 24,
              values: timeRange,
              onChanged: (values) => setState(() => timeRange = values),
              labels: RangeLabels(
                _formatTime(timeRange.start),
                _formatTime(timeRange.end),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('00:00', style: TextStyle(color: Colors.white54)),
              Text('24:00', style: TextStyle(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 24),
          // Пространства
          const Text(
            'Пространство:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: spaces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final isSelected = selectedSpaceIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => selectedSpaceIndex = i),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF18181C)
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF5B5BFF)
                                : Colors.white24,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          spaces[i]['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spaces[i]['address']!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Залы
          const Text(
            'Концептуальные залы:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                halls
                    .map(
                      (hall) => _FilterChip(
                        label: hall,
                        selected: selectedHalls.contains(hall),
                        onTap:
                            () => setState(() {
                              if (selectedHalls.contains(hall)) {
                                selectedHalls.remove(hall);
                              } else {
                                selectedHalls.add(hall);
                              }
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
          // Технологии
          const Text(
            'Технологии:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                technologies
                    .map(
                      (tech) => _FilterChip(
                        label: tech,
                        selected: selectedTechnologies.contains(tech),
                        onTap:
                            () => setState(() {
                              if (selectedTechnologies.contains(tech)) {
                                selectedTechnologies.remove(tech);
                              } else {
                                selectedTechnologies.add(tech);
                              }
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
          // Языки
          const Text(
            'Языки:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                languages
                    .map(
                      (lang) => _FilterChip(
                        label: lang,
                        selected: selectedLanguages.contains(lang),
                        onTap:
                            () => setState(() {
                              if (selectedLanguages.contains(lang)) {
                                selectedLanguages.remove(lang);
                              } else {
                                selectedLanguages.add(lang);
                              }
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
          // Жанры
          const Text(
            'Жанры:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                genres
                    .map(
                      (genre) => _FilterChip(
                        label: genre,
                        selected: selectedGenres.contains(genre),
                        onTap:
                            () => setState(() {
                              if (selectedGenres.contains(genre)) {
                                selectedGenres.remove(genre);
                              } else {
                                selectedGenres.add(genre);
                              }
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 32),
          // Кнопка применить
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5BFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: применить фильтры
                Navigator.of(context).pop();
              },
              child: const Text(
                'Применить фильтры',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double hour) {
    final h = hour.floor().toString().padLeft(2, '0');
    final m = ((hour - hour.floor()) * 60).round().toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B5BFF) : const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5B5BFF) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CalendarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: const Center(
        child: Icon(Icons.calendar_today, color: Colors.white54, size: 28),
      ),
    );
  }
}
