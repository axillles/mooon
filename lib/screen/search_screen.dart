import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF323232),
      body: SafeArea(
        child: Stack(
          children: [
            // Крестик справа сверху
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF323232),
                    size: 28,
                  ),
                ),
              ),
            ),
            // Основное содержимое
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                    cursorColor: const Color(0xFF5B5BFF),
                    decoration: InputDecoration(
                      hintText: 'введите, например, Человек паук',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5B5BFF),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5B5BFF),
                          width: 2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Результат поиска',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child:
                        _query.isEmpty
                            ? const SizedBox.shrink()
                            : const Text(
                              'Тут будут результаты поиска',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
