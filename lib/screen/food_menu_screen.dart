import 'package:flutter/material.dart';

class FoodMenuScreen extends StatelessWidget {
  const FoodMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121218),
        elevation: 0,
        title: const Text('Меню в зал'),
      ),
      body: const Center(
        child: Text(
          'Здесь будет меню заказа еды',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
