import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Ініціалізація сповіщень не повинна блокувати запуск UI.
  try {
    await container.read(notificationServiceProvider).init();
  } catch (error, stack) {
    debugPrint('Помилка ініціалізації сповіщень: $error\n$stack');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const XSilentApp(),
    ),
  );

  // Синхронізація нагадувань (з генерацією озвучень) — у фоні, щоб не тримати
  // сплеш; список підтягнеться зі стріму БД одразу.
  container.read(remindersRepositoryProvider).seedDefaultIfEmpty().catchError(
        (Object error, StackTrace stack) =>
            debugPrint('Помилка синхронізації нагадувань: $error\n$stack'),
      );
}
