import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers.dart';
import 'services/app_settings.dart';

/// Глобальний ланцюжок, що серіалізує виклики `reconcile` — щоб «застаріле»
/// перепланування (з локаллю до її уточнення рушієм) не перетерло свіже.
Future<void> _reconcileChain = Future<void>.value();

void _scheduleReconcile(ProviderContainer container) {
  _reconcileChain = _reconcileChain.then((_) {
    // Читаємо репозиторій у момент виконання — тож завжди беремо поточну мову,
    // а не ту, що була на момент постановки в чергу.
    return container.read(remindersRepositoryProvider).reconcile();
  }).catchError(
    (Object error, StackTrace stack) =>
        debugPrint('Помилка синхронізації нагадувань: $error\n$stack'),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

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

  // Сід вбудованого нагадування + перелокалізація його тексту й перепланування
  // сповіщень. Спрацьовує на старті та після кожної зміни фактичної мови
  // (зокрема коли рушій уточнює локаль пристрою вже після запуску).
  container.listen(
    effectiveLocaleProvider,
    (previous, next) => _scheduleReconcile(container),
    fireImmediately: true,
  );
}
