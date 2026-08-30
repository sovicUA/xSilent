# Хвилина мовчання (xSilent)

Flutter-застосунок: щоденне нагадування вшанувати памʼять хвилиною мовчання
(за замовчуванням о 9:00) + власні нагадування з довільним часом і днями тижня.

Переписаний з нативної Android-версії (Kotlin/Compose/Room/AlarmManager).
Історія й обґрунтування архітектурних рішень — [DECISIONS.md](DECISIONS.md).

## Стек

| Шар | Пакет |
|---|---|
| Сховище | `drift` (поверх SQLite) |
| Стан | `flutter_riverpod` |
| Сповіщення | `flutter_local_notifications` + `timezone` |

## Розробка

```bash
flutter pub get
dart run build_runner build          # генерує database.g.dart
flutter analyze
flutter test
flutter run                          # потрібен Android/iOS пристрій або емулятор
```

Після зміни таблиць у `lib/database/database.dart` перезапустити `build_runner`
(або тримати `dart run build_runner watch`).

## Структура

```
lib/
  main.dart                       bootstrap
  app.dart                        MaterialApp / тема / локаль
  models/weekdays.dart            дні тижня як бітова маска
  database/database.dart          drift: таблиця Reminders, AppDatabase
  data/reminders_repository.dart  CRUD + синхронізація зі сповіщеннями
  services/notification_service.dart
  providers.dart                  Riverpod-провайдери
  screens/
    home_screen.dart              список нагадувань
    edit_reminder_screen.dart     створення / редагування
```

## Платформи

- **Android** — дозволи та ресивери прописані в `android/app/src/main/AndroidManifest.xml`;
  увімкнено core library desugaring (`android/app/build.gradle.kts`).
- **iOS** — `UNUserNotificationCenter` delegate у `ios/Runner/AppDelegate.swift`;
  збірка на macOS з Xcode.
