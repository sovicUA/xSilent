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
| `AlarmManager` + `AlarmReceiver` + ручний розрахунок наступного спрацювання | `flutter_local_notifications` (візуальне сповіщення) + `android_alarm_manager_plus` (озвучення, Android) — див. розділ «Озвучення сповіщень» |
| `BootReceiver` (відновлення будильників після перезавантаження) | `flutter_local_notifications` сам реєструє ресивер; `android_alarm_manager_plus` — через `rescheduleOnReboot: true` + `RebootBroadcastReceiver`. На iOS ОС зберігає заплановані сповіщення без додаткового коду |

## Середовище розробки

- Редактор: VS Code (з переходом на Claude Code для подальшої розробки).
- Збірка/тестування Android і iOS — локально, обмежень немає.
- Git/GitHub: репозиторій — `https://github.com/sovicUA/xSilent` (гілка `main`). Прямого
  доступу через чат-інтерфейс Claude до GitHub немає — робота з репозиторієм ведеться
  через Claude Code або звичайний git локально. `gh` CLI на машині не встановлено;
  автентифікація для пушу налаштована власником.

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
- [x] Іконка застосунку: герб України + полум'я свічки, товстий чорний контур із заокругленими кутами, фон — прапор України (синьо-жовтий). Друга редакція (`icon_package_2`, 2026-08-30). Джерела в `assets/icon/`, генерація `dart run flutter_launcher_icons` (конфіг у `pubspec.yaml`). Растрові майстри 1024 + Play Store 512 — у `design/`.
- [x] Монохромна іконка сповіщень `res/drawable-*/ic_stat_xsilent.png` (білий силует тризуба+свічки на прозорому тлі). Статус-бар/банер вимагають alpha-only іконку, інакше — суцільний білий квадрат. Генерується скриптом із `assets/icon/app_icon_foreground.png`. Підключена в `NotificationService`: `AndroidInitializationSettings('ic_stat_xsilent')` + `icon:`/`color: 0xFF3F5C78` у деталях, додана в `keep.xml`.
- [x] Канали сповіщень: `moment_of_silence` (MAX) для вбудованого без озвучки, `custom_reminders` (HIGH) для власних без озвучки, `spoken_reminders_v2` (MAX, звук — короткий **гонг** `res/raw/gong.wav` ≈ 1.4 с, + вібрація) для будь-яких з `speakAloud`. Фоновий ізолят чекає `NotificationService.gongLeadIn` (1500 мс) після спрацювання, потім озвучує — керована послідовність «гонг → пауза → оголошення» без накладання. Старі канали `reminders` і `spoken_reminders` видаляються в `init()`. Вибір каналу — `speakAloud ? spoken_reminders_v2 : (isBuiltIn ? moment_of_silence : custom_reminders)`. Гонг згенеровано скриптом (Risset-bell партіали), лежить у `res/raw`, у бандл iOS ще не вшито. **Важливо:** release-збірка вмикає resource shrinker, який видаляв `gong.wav` (посилання лише за іменем із Dart) → потрібен `android/app/src/main/res/raw/keep.xml` з `tools:keep="@raw/gong"`. Також `main()` тепер має try/catch навколо ініціалізації сповіщень — збій планувальника більше не блокує запуск UI.
- [x] Окремий текст тіла сповіщення: нова nullable-колонка `body` у `Reminders` (drift schemaVersion 2 + міграція `addColumn`), поле «Текст сповіщення» у формі редагування. Порожнє → сповіщення лише з назвою. Вбудоване нагадування сідиться з текстом «УВАГА! Оголошується загальнонаціональна хвилина мовчання.»; для баз зі схеми v1 це тіло бекфілиться в `seedDefaultIfEmpty`.
- [x] Екран налаштувань — заглушка `lib/screens/settings_screen.dart` + кнопка-шестерня в AppBar головного екрана. Наповнення пізніше.
- [x] `.gitignore` + `.gitattributes` (нормалізація LF), гілка `main`, перший коміт `c9cf1ec` опубліковано на `github.com/sovicUA/xSilent`.
- [x] Озвучення сповіщень (TTS), Android. `android_alarm_manager_plus` планує точний alarm паралельно до `zonedSchedule`; при спрацюванні фоновий ізолят (`speechAlarmCallback` у `lib/services/speech_alarm.dart`) озвучує `body` через `flutter_tts` (`uk-UA` з фолбеком) і переставляє себе на наступний тиждень. Візуальне сповіщення від `zonedSchedule` лишається незалежним (працює навіть якщо OEM вб'є ізолят). Колонка `speakAloud` (schemaVersion 3). Прапорець «Озвучити сповіщення» в редакторі: активний лише за наявності опису, за замовчуванням увімкнений коли опис введено. Кнопка «Прослухати» (прев'ю). Маніфест: `WAKE_LOCK`, `FOREGROUND_SERVICE`, сервіс+ресивери плагіна, `TTS_SERVICE` у `<queries>`.
- [x] Функціональна перевірка голосу на пристрої (Lenovo TB305XU, Android 15) — **пройдено**. З вимкненим екраном: alarm спрацював точно в час → гонг каналу → пауза 1.5 с → фоновий ізолят озвучив текст українською (Google TTS, вбудований голос `uk-ua-x-hfd-seanet-embedded`) через динамік + сповіщення + alarm переставився на наступний тиждень. Послідовність «гонг → пауза → голос» без накладання. Спостереження: Android 15 «audio hardening» відхиляє запит audio focus від фонового застосунку (`focus: true`), але саме відтворення проходить. Якщо колись знадобиться дакінг музики під час озвучення — переносити callback у foreground service.
- [x] Озвучення на заблокованому пристрої (Motorola Edge 50 Fusion, Android 16). Проблема: TTS з фонового ізоляту відкладалося до розблокування (чути лише гонг), бо Android 16 «AudioHardening» глушить фонове відтворення звичайного медіа. Фікс: `tts.setAudioAttributesForNavigation()` у `configureTts` — озвучення грає з класом `USAGE_ASSISTANCE_NAVIGATION_GUIDANCE` («голос навігатора»), який виключений з background-mute (як голос Google Maps). Перевірено на Motorola із заблокованим екраном — **працює**. (У логах лишається попередження `AudioHardening ... would be muted` для TTS-сервісу, але нав-guidance відтворюється попри це.)
- [ ] iOS-озвучення у фоні (окремий етап; `speakAloud` та прев'ю вже кросплатформні).
- [x] Кнопки на банері сповіщення: **«Гаразд»** і **«Відкласти»** — обидві з `cancelNotification: true` (ховають сповіщення). «Відкласти» (на `NotificationService.snoozeDelay` = 5 хв) — лише для власних, не для вбудованого. **Обов'язково:** `<receiver ... ActionBroadcastReceiver />` в AndroidManifest, інакше кнопки нічого не роблять (плагін не обробляє action). Топ-рівневий `notificationActionCallback` (foreground + background), payload у JSON (id/title/body/speak/builtIn, без звернення до БД). Відкладене сповіщення має id `reminderId*8` (weekday 0); озвучення відкладеного — разовий alarm `armSnoozeAlarm`, `speechAlarmCallback` для weekday 0 говорить, але не переставляє на +тиждень.
- [ ] Локалізація рядків (назви каналів, тексти сповіщень, кнопки) — зараз хардкод українською.
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
