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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const XSilentApp(),
    ),
  );

  // Перше (негайне) спрацювання цього listener бере на себе весь bootstrap
  // сповіщень: `reconcile()` робить `_notifications.init()` (канали, таймзони),
  // сідить вбудоване нагадування та планує все. Далі — після кожної зміни
  // фактичної мови. Ланцюжок серіалізує виклики, помилки логуються й не
  // блокують UI (тому окремий `await init()` до `runApp` не потрібен).
  container.listen(
    effectiveLocaleProvider,
    (previous, next) => _scheduleReconcile(container),
    fireImmediately: true,
  );

  // Зміна голосу озвучення — теж через серіалізований ланцюжок: `reconcile()`
  // перегенерує всі оголошення (голос входить у хеш каналу).
  container.listen(
    ttsVoiceControllerProvider,
    (previous, next) => _scheduleReconcile(container),
  );
}
