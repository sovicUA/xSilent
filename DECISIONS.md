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
| `AlarmManager` + `AlarmReceiver` + ручний розрахунок наступного спрацювання | `flutter_local_notifications.zonedSchedule` (`DateTimeComponents.dayOfWeekAndTime` — щотижневий повтор вбудований) |
| `BootReceiver` (відновлення будильників після перезавантаження) | `flutter_local_notifications` сам реєструє ресивер. На iOS ОС зберігає заплановані сповіщення без додаткового коду |

## Середовище розробки

- Редактор: VS Code (з переходом на Claude Code для подальшої розробки).
- Збірка/тестування Android і iOS — локально, обмежень немає.
- Git/GitHub: репозиторій — `https://github.com/sovicUA/xSilent` (гілка `main`). Прямого
  доступу через чат-інтерфейс Claude до GitHub немає — робота з репозиторієм ведеться
  через Claude Code або звичайний git локально. `gh` CLI на машині не встановлено;
  автентифікація для пушу налаштована власником.

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
- [x] **Озвучення переписано на «звук каналу» (Option A, 2026-08-31).** Пункти 83–85 вище — застаріла реалізація через `android_alarm_manager_plus` (ненадійна на Motorola вдень — Android глушив фонове аудіо застосунку). Нова архітектура:
  - `android_alarm_manager_plus` **видалено**. Щотижневий повтор — знову `zonedSchedule` (`DateTimeComponents.dayOfWeekAndTime`).
  - При збереженні/прев'ю нагадування `AnnouncementService` (`lib/services/announcement_service.dart`) синтезує `body` через `flutter_tts.synthesizeToFile`, склеює в Dart «гонг (`assets/audio/gong.wav`) + 400 мс тиші + мовлення» в один WAV (`lib/utils/wav.dart`), гучність — множенням семплів.
  - Нативний `SoundStore` (`android/.../SoundStore.kt` + MethodChannel `xsilent/sound_store`) кладе WAV у MediaStore `Notifications/xSilent`, `IS_NOTIFICATION=1` → `content://` URI. **Без дозволів** (власні файли, Android 10+).
  - Канал `spoken_r{id}_{hash}` (hash = **FNV-1a 32-біт** над `body|volume` — `String.hashCode` у Dart рандомізується на кожен запуск, тут потрібен детермінований), `sound: UriAndroidNotificationSound(uri)`, importance MAX, група `spoken_group`. Зміна тексту/гучності → новий hash → новий канал+файл, старі підчищаються. `sync()` пропускає синтез, якщо канал із цільовим hash уже існує (`getNotificationChannels()`) — на старті нічого не переґенеровується.
  - **Систе­ма програє звук каналу незалежно від фонових обмежень** — те, що робив гонг, тепер робить усе оголошення.
  - Нова колонка `Reminders.announcementVolume` (real, default 1.0), schemaVersion **4**. Повзунок «Гучність озвучення» в редакторі (per-reminder).
  - Прев'ю (`Прослухати`): та сама генерація → програвання файлу через `audioplayers`; якщо тривалість > `AnnouncementService.maxLength` (30 с) — SnackBar-попередження про обрізання.
  - Гонг замінено на `~/Downloads/gong.mp3` користувача (декодовано в `assets/audio/gong.wav` 24кГц моно скриптом `scratchpad/decode_gong.py`).
  - `main()`: `seedDefaultIfEmpty` тепер fire-and-forget після `runApp` (синтез не тримає сплеш).
  - **Перевірено на Motorola (Android 16): грає заблокованим/вдень — працює** (те, що не працювало через alarm-менеджер). Канал має `mSound=content://media/...`, файл у MediaStore `Notifications/xSilent` `is_notification=1`. Після фіксу hash-у на старті нема churn каналів/файлів (2 канали, 2 файли, стабільно). Кнопка «Прослухати» + повзунок гучності — ок.
- [x] **Два гонги + послідовність «хвилини мовчання» (2026-08-31).**
  - **Основний гонг** (`assets/audio/main_gong.wav` + `res/raw/main_gong.wav`) — для вбудованого нагадування. **Додатковий гонг** (`res/raw/additional_gong.wav`, обрізаний до 1.8 с з `~/Downloads/soundreality-notification-tone-443095.mp3`, `scratchpad/make_additional_gong.py`) — для власних нагадувань користувача.
  - `AnnouncementService` тепер приймає `Gong` (main/additional) — hash каналу залежить від гонга; вибір: `reminder.isBuiltIn ? Gong.main : Gong.additional`.
  - Канали з новими id (старі видалено в `init()`): `moment_of_silence_v2` (main_gong), `custom_reminders_v2` (additional_gong), `mos_pre` (additional_gong), `mos_end` (main_gong).
  - Вбудоване нагадування планує **3 сповіщення на день** (id-бази `_preIdBase`/`_endIdBase`):
    - `T-10с` (`_preLead`): «Нагадування про хвилину мовчання» + додатковий гонг (`mos_pre`).
    - `T`: основне оголошення (`spoken_r1_*`, основний гонг + TTS).
    - `T+1хв` (`_silenceLength`): «Хвилину мовчання завершено» + основний гонг (`mos_end`).
  - `dayOfWeekAndTime` коректно зберігає секунди — перевірено в `dumpsys alarm` (08:59:50 / 09:00:00 / 09:01:00).
- [x] Дефолтна назва нового нагадування — «Сповіщення» (не «Хвилина мовчання»).
- [x] Головний екран (2026-08-31): вбудоване «Хвилина мовчання» завжди перше, акцентоване (`Card` на `primaryContainer`, іконка-вогник `lib/widgets/candle_flame.dart` — `CustomPainter`, монохром у `onPrimaryContainer`). Далі роздільник `──── НАГАДУВАННЯ ────` (`_SectionSeparator`, лише коли є власні), потім власні за часом. Макет узгоджено з користувачем — `design/mockups/reminders-list.html` (артефакт `claude.ai/code/artifact/5d2ff3f8...`).
- [x] Кнопки на банері сповіщення: **«Гаразд»** і **«Відкласти»** — обидві з `cancelNotification: true` (ховають сповіщення). «Відкласти» (на `NotificationService.snoozeDelay` = 5 хв) — лише для власних, не для вбудованого. **Обов'язково:** `<receiver ... ActionBroadcastReceiver />` в AndroidManifest, інакше кнопки нічого не роблять (плагін не обробляє action). Топ-рівневий `notificationActionCallback` (foreground + background), payload у JSON. Відкладене сповіщення має id `reminderId*8` (weekday 0); планується тим самим `zonedSchedule` на тому ж каналі.

- [x] **Локалізація укр/англ + вибір мови (2026-08-31).**
  - Flutter `gen_l10n`: `l10n.yaml`, `lib/l10n/app_uk.arb` (шаблон) + `app_en.arb`, генерований `lib/l10n/app_localizations*.dart` **комітимо**. Клас `L10n`, топ-рівнева синхронна `lookupL10n(Locale)` — тож рядки доступні в провайдерах і фоновому ізоляті (`notificationActionCallback` бере `locale` з payload).
  - `lib/services/app_settings.dart`: `localeControllerProvider` (`Notifier<Locale?>`, `null` = авто, зберігається в `shared_preferences` ключ `app_locale`); `deviceLocalesProvider` (`Notifier` + `WidgetsBindingObserver.didChangeLocales` — щоб пережити стартову гонку, коли `PlatformDispatcher.locales` ще віддає `ro.product.locale`); `effectiveLocaleProvider` = вибір користувача або `regionLocale(deviceLocales)` (країна ∈ {UA,RU,BY} → uk, інакше en). Це **єдине джерело** і для `MaterialApp.locale`, і для `l10nProvider` (жодних `Localizations.localeOf` / postFrame).
  - `RemindersRepository.reconcile()` (замінив `seedDefaultIfEmpty` + `onLocaleChanged`): сід вбудованого нагадування + перелокалізація його `title`/`body`, якщо збігаються з дефолтом будь-якої мови (ручні правки не чіпає) + `_notifications.init()` + `syncAll`. Викликається з **єдиного глобального `Future`-ланцюжка** в `main.dart` через `container.listen(effectiveLocaleProvider, fireImmediately: true)` — серіалізовано, репозиторій читається в момент виконання (свіжа мова), тож застаріле перепланування не перетирає нове.
  - `NotificationService._reconcile`/`sync`: канали (`chan*Name/Desc`), тексти pre/end, кнопки, назва групи, `spokenChannelName/Desc` — через `l10n`. Прибирання старих `spoken_r*` каналів/файлів тепер і в гілці повторного використання каналу (не лише при створенні нового).
  - Перевірено на Lenovo (uk-UA, `ro.product.locale=en-US`): свіжа інсталяція → все укр; перемикання на English у налаштуваннях → UI + канали + текст вбудованого наживо англійською, TTS переозвучено; назад на «Авто» → все укр, англ. `spoken_*` канал → `mDeleted=true`.

- [x] **Фікси планування сповіщень (2026-09-01, гілка `fix/notification-scheduling-bugs`).**
  - `_cancelNotifications` більше не скасовує pre/end сповіщення послідовності «хвилини мовчання» (`_preIdBase`/`_endIdBase` — глобальні id) під час `sync`/`purge` **власного** нагадування. Тепер приймає `isBuiltIn` і чіпає pre/end лише для вбудованого. Раніше будь-яка правка власного нагадування тихо вимикала попередження T−10 с і сигнал T+1 хв до наступного `reconcile()`.
  - Кнопка «Відкласти» у фоновому ізоляті: `snooze()` тепер викликає `initCore()` (виділено з `init()` — таймзони + `_plugin.initialize`, без чіпання каналів) перед `zonedSchedule`. Без цього плагін у фоновому ізоляті не мав контексту й перепланування тихо не відбувалося.

- [x] **Середні знахідки код-рев'ю (2026-09-02, гілка `fix/review-medium-findings`).**
  - `requestPermissions()`: `requestExactAlarmsPermission()` тепер лише за `!canScheduleExactNotifications()`. З `USE_EXACT_ALARM` у маніфесті це завжди `true`, тож виклик, що кидав у системні налаштування на кожному холодному старті, більше не спрацьовує.
  - `main()`: прибрано окремий `await notificationService.init()` до `runApp` — bootstrap сповіщень повністю на першому (негайному) спрацюванні `container.listen(effectiveLocaleProvider)` → `reconcile()` → `init()`. Прибрано подвійну ініціалізацію плагіна на старті.
  - `utils/next_occurrence.dart` видалено (мертвий код — планувальник використовував власний `_nextInstanceOf`). Логіку винесено в top-level `@visibleForTesting nextInstanceOf(now, hour, minute, weekday)` у `notification_service.dart`; тести — `test/notification_scheduling_test.dart` (перевіряють саме її). `test/widget_test.dart` розбито на `notification_scheduling_test.dart` + `weekdays_test.dart`.
  - `readWav()` кидає `FormatException` для не-PCM / не-16-біт / порожнього `fmt`. `AnnouncementService._renderLocked` обгортає читання WAV від TTS → `AnnouncementException` (тож `sync` робить fallback на канал без озвучення, а не падає) і відхиляє не-моно вихід.
  - Приватність озвучених WAV у спільному MediaStore — задокументовано в `README.md` (не міняємо: система інакше не прочитає звук каналу).

## Відкриті задачі

- [ ] Живий тест 3-частинної послідовності «хвилини мовчання» на пристрої (заблокований екран).
- [ ] Перевірити збереження часу власного нагадування: під час тесту на Motorola (Android 16) нагадування зберігалося з `hour/minute` 0:00, хоча в `showTimePicker` вибирали інший час. Можливо, результат пікера не застосовується (`_pickTime` в `edit_reminder_screen.dart`) або специфіка Material 3 time picker на Android 16.
- [ ] Реальні скріншоти застосунку для лістингу Play Store.
- [ ] iOS: збірка/тест; фонове озвучення через `Library/Sounds/` (модель даних уже кросплатформна).
- [ ] Release signing config (зараз release підписується debug-ключем; акаунт розробника ще на верифікації).
- [ ] Більше тестів (`NotificationService`, `AnnouncementService`, репозиторій, віджети).
- [ ] Міграція `flutter_timezone` на Built-in Kotlin (попередження при збірці) або заміна пакета.
- [ ] CI (`.github/workflows`): analyze + test + збірка.
- [ ] Вирішити, чи повертати можливість дублювання нагадувань у месенджери (раніше прибрано).

## Стек і структура

Актуальний перелік пакетів і дерево `lib/` — у [README.md](README.md).
Обґрунтування ключових виборів:

- **drift** (замість `sqflite`) — реактивні стріми з БД, типобезпечні запити,
  вбудовані міграції.
- **Riverpod** (замість Provider) — compile-time safe, не залежить від `BuildContext`,
  зручно тестувати.
- **flutter_local_notifications** — `zonedSchedule` з `DateTimeComponents.dayOfWeekAndTime`
  дає щотижневий повтор без ручного розрахунку наступного спрацювання.
- **Озвучення як звук каналу** (не фоновий TTS) — систе­ма програє звук сповіщення
  незалежно від обмежень фонових застосунків; єдиний надійний спосіб на агресивних
  OEM (Motorola). Див. пункт «Option A» вище.
