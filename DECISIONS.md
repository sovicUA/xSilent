# Хвилина мовчання — рішення щодо архітектури

Цей документ підсумовує рішення, ухвалені під час обговорення переходу застосунку
на кросплатформну технологію. Призначення: дати Claude Code (або будь-кому іншому)
повний контекст, не переказуючи історію обговорення заново.

## Контекст

Початкова версія застосунку була написана нативно під Android: Kotlin + Jetpack Compose +
Room + AlarmManager. Функціонал: нагадування "Хвилина мовчання" щодня о 9:00 (за замовчуванням)
+ можливість додавати власні нагадування із заданим часом і довільним набором днів тижня.

Окремо обговорювалась і була **відхилена (прибрана з коду)** ідея дублювання нагадувань у
WhatsApp/Signal через кнопку дії в сповіщенні — з'ясувалось, що жоден з цих месенджерів не дає
стороннім застосункам API для автоматичної відправки повідомлень без участі людини. Рішення:
поки не реалізовувати, можна повернутись до цього пізніше за потреби (генерація кнопки дії,
що відкриває чат/групу з передзаповненим текстом, залишаючи фінальний клік "Надіслати" людині).

## Рішення: перехід на Flutter

**Мова/фреймворк:** Flutter (Dart).

**Причина вибору:** пріоритет — найзріліша й найпопулярніша кросплатформна технологія,
навіть ціною повного переписування наявного Kotlin-коду (перевага над Kotlin Multiplatform,
яка б дозволила зберегти більше коду, але є менш обкатаною саме для iOS-цілі).

**Обмежень щодо збірки під iOS немає** — у розробника є MacBook і Mac Mini з Xcode.

**Розглянуті й відхилені альтернативи:**
- Kotlin Multiplatform + Compose Multiplatform — дозволило б зберегти найбільше коду
  (Room 2.7+ мультиплатформний, архітектура Entity/DAO/Repository/ViewModel переноситься),
  але відхилено на користь зрілішої екосистеми Flutter.
- React Native — рівноцінний за зрілістю варіант; не обрано, оскільки немає наявного
  досвіду з React/JS-екосистемою, тож перевага в порозі входу не реалізується.
- .NET MAUI — менш популярний вибір саме для мобільних застосунків, слабша підтримка у VS Code.
- Нативний Swift + спільна Kotlin-логіка через KMP — найякісніший UI, але вимагає писати
  два UI замість одного; відхилено як найбільш трудомісткий варіант.

## Плановане технологічне відображення (Kotlin → Flutter)

| Було (Android/Kotlin) | Стає (Flutter/Dart) |
|---|---|
| Room (Entity/DAO/Database) | **`drift`** (обрано 2026-08-30) |
| Jetpack Compose UI | Flutter widgets |
| ViewModel + StateFlow | **Riverpod** (обрано 2026-08-30) |
| `AlarmManager` + `AlarmReceiver` + ручний розрахунок наступного спрацювання | `flutter_local_notifications` — розклад по днях тижня вбудований у пакет |
| `BootReceiver` (відновлення будильників після перезавантаження) | Не потрібен: `flutter_local_notifications` сам реєструє потрібний ресивер на Android; на iOS ОС зберігає заплановані сповіщення без додаткового коду |

## Середовище розробки

- Редактор: VS Code (з переходом на Claude Code для подальшої розробки).
- Збірка/тестування Android і iOS — локально, обмежень немає.
- Git/GitHub: репозиторій створюється власником проєкту; прямого доступу через чат-інтерфейс
  Claude до GitHub немає (немає підключеного конектора) — вся робота з репозиторієм ведеться
  через Claude Code або звичайний git локально.

## Наявний Android-проєкт (Kotlin, нативний)

Попередня нативна Android-версія лишається як окремий референс (не видаляти одразу):
структура з Room + Compose + AlarmManager, включно з CI (`.github/workflows/android-ci.yml`)
і Gradle wrapper. При потребі може слугувати джерелом порівняння логіки під час портування
на Dart (особливо розрахунок `nextTriggerMillis` у `AlarmScheduler.kt` — еквівалентна
логіка знадобиться, хоч `flutter_local_notifications` і бере частину цього на себе).

## Наступні кроки

- [x] Встановити Flutter SDK + Android toolchain на Windows (Flutter 3.47.2, Android SDK 36, NDK 28.2.13676358, 2026-08-30).
- [x] Створити структуру Flutter-проєкту (`flutter create`, app id `ua.org.sovic.xsilent`, пакет `xsilent`).
- [x] Модель даних (`Reminder`) і сховище на `drift` — `lib/database/database.dart`, `lib/data/reminders_repository.dart`.
- [x] Керування станом на Riverpod — `lib/providers.dart`.
- [x] Планування нагадувань через `flutter_local_notifications` + `timezone` — `lib/services/notification_service.dart` (по одному сповіщенню на кожен день тижня, `DateTimeComponents.dayOfWeekAndTime`).
- [x] Базовий UI — `lib/screens/home_screen.dart` (список + свайп-видалення + перемикач), `lib/screens/edit_reminder_screen.dart` (час, назва, дні тижня).
- [x] Android-конфіг: дозволи (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`), ресивери, core library desugaring. Debug APK збирається.
- [x] Емулятор Android для тестування: AVD `Motorola_Edge_50_Fusion` (база pixel_7 — 1080×2400 @ 420dpi, як реальний пристрій; API 35, Play Store, x86_64). Застосунок запущено, працює.
- [~] Перевірити на реальному пристрої та на iOS. Android: release APK встановлено й запущено на Motorola Edge 50 Fusion (Android 16 / API 36, arm64). iOS — ще ні.
- [x] Іконка застосунку: герб України + полум'я свічки, товстий чорний контур із заокругленими кутами, фон — прапор України (синьо-жовтий). Друга редакція (`icon_package_2`, 2026-08-30). Джерела в `assets/icon/`, генерація `dart run flutter_launcher_icons` (конфіг у `pubspec.yaml`). Растрові майстри 1024 + Play Store 512 — у `design/`. Згенерована й у release APK; на пристрій ще НЕ перевстановлена після оновлення.
- [x] Канали сповіщень: два фіксовані — `moment_of_silence` («Хвилина мовчання», importance MAX) для вбудованого нагадування і `custom_reminders` («Власні нагадування», importance HIGH) для решти. Старий єдиний канал `reminders` видаляється в `init()`. Вибір каналу — за `reminder.isBuiltIn`.
- [x] Окремий текст тіла сповіщення: нова nullable-колонка `body` у `Reminders` (drift schemaVersion 2 + міграція `addColumn`), поле «Текст сповіщення» у формі редагування. Порожнє → сповіщення лише з назвою. Вбудоване нагадування сідиться з текстом «УВАГА! Оголошується загальнонаціональна хвилина мовчання.»; для баз зі схеми v1 це тіло бекфілиться в `seedDefaultIfEmpty`.
- [x] Екран налаштувань — заглушка `lib/screens/settings_screen.dart` + кнопка-шестерня в AppBar головного екрана. Наповнення пізніше.
- [ ] Локалізація рядків (назви каналів, тексти сповіщень) — зараз хардкод українською.
- [ ] Дозвіл на сповіщення (`POST_NOTIFICATIONS`) у release-збірці — перевірити, що системний запит показується.
- [ ] `.gitattributes` (`* text=auto eol=lf`) перед першим комітом — git попереджає про LF→CRLF на всіх файлах.
- [ ] Перший git-коміт (репозиторій `git init` зроблено, нічого не закомічено).
- [ ] Release signing config (зараз release підписується debug-ключем).
- [ ] Тести: `NotificationService`, репозиторій, віджети.
- [ ] Міграція `flutter_timezone` на Built-in Kotlin (попередження при збірці) або заміна пакета.
- [ ] CI (`.github/workflows`), аналог старого `android-ci.yml`.
- [ ] Вирішити, чи повертати можливість дублювання в месенджери (раніше прибрано).

## Структура проєкту (lib/)

- `main.dart` — bootstrap: init сповіщень, seed вбудованого нагадування, `UncontrolledProviderScope`.
- `app.dart` — `MaterialApp`, тема (Material 3), локаль `uk`.
- `models/weekdays.dart` — дні тижня як бітова маска (біт `weekday-1`, [DateTime.weekday]).
- `database/database.dart` (+ `.g.dart`) — drift: таблиця `Reminders`, `AppDatabase`.
- `data/reminders_repository.dart` — CRUD + синхронізація зі сповіщеннями.
- `services/notification_service.dart` — `flutter_local_notifications` + `timezone`.
- `providers.dart` — Riverpod: `databaseProvider`, `notificationServiceProvider`, `remindersRepositoryProvider`, `remindersProvider` (Stream).
- `screens/` — `home_screen.dart`, `edit_reminder_screen.dart`.

## Стек (зафіксовано 2026-08-30)

- **Flutter (Dart)** — кросплатформа (Android + iOS).
- **drift** — локальне сховище (поверх SQLite), реактивні стріми, типобезпечні запити, вбудовані міграції.
- **Riverpod** — керування станом (compile-time safe, не залежить від `BuildContext`).
- **flutter_local_notifications** — локальні сповіщення з розкладом по днях тижня.
- **timezone** — коректний розрахунок часу спрацювання для zonedSchedule.
