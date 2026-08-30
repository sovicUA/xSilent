import 'dart:io' show Platform;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Ініціалізація сповіщень/alarm-ів не повинна блокувати запуск UI: якщо
  // щось із планувальником піде не так, застосунок має лишитись придатним
  // для перегляду й редагування нагадувань.
  try {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }
    await container.read(notificationServiceProvider).init();
    await container.read(remindersRepositoryProvider).seedDefaultIfEmpty();
  } catch (error, stack) {
    debugPrint('Помилка ініціалізації сповіщень: $error\n$stack');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const XSilentApp(),
    ),
  );
}
