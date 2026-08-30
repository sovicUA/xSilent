import 'package:flutter/material.dart';

/// Екран налаштувань. Поки заглушка — наповнення додається пізніше
/// (дозволи, стандартний час, поведінка сповіщень тощо).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_outlined, size: 64),
              SizedBox(height: 16),
              Text('Тут зʼявляться налаштування', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
