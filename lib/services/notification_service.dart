import 'dart:convert';
import 'dart:ui' show Color, DartPluginRegistrant;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database.dart';
import '../models/weekdays.dart';
import 'speech_alarm.dart';

/// Планування локальних сповіщень для нагадувань.
///
/// Кожне нагадування розкладається на окремі сповіщення — по одному на кожен
/// увімкнений день тижня — бо [FlutterLocalNotificationsPlugin.zonedSchedule] з
/// [DateTimeComponents.dayOfWeekAndTime] повторює подію лише для одного дня.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Канал вбудованого нагадування «Хвилина мовчання» — максимальна важливість.
  static const AndroidNotificationChannel _silenceChannel =
      AndroidNotificationChannel(
    'moment_of_silence',
    'Хвилина мовчання',
    description: 'Загальнонаціональна хвилина мовчання',
    importance: Importance.max,
  );

  /// Канал нагадувань, які користувач створив самостійно.
  static const AndroidNotificationChannel _customChannel =
      AndroidNotificationChannel(
    'custom_reminders',
    'Власні нагадування',
    description: 'Нагадування, які ви додали самостійно',
    importance: Importance.high,
  );

  /// Канал нагадувань з озвученням: короткий гонг замість стандартного звуку
  /// сповіщення, після якого (з паузою) фоновий ізолят проговорює текст —
  /// керована послідовність «гонг → пауза → оголошення» без накладання.
  /// `gong` — `android/app/src/main/res/raw/gong.wav`.
  static const AndroidNotificationChannel _spokenChannel =
      AndroidNotificationChannel(
    'spoken_reminders_v2',
    'Нагадування з озвученням',
    description: 'Гонг, після якого текст проговорюється вголос',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('gong'),
  );

  /// Попередня версія каналу озвучення (без звуку) — видаляється в [init].
  static const String _legacySpokenChannelId = 'spoken_reminders';

  /// Монохромна іконка для статус-бару / банера сповіщення
  /// (`res/drawable-*/ic_stat_xsilent.png` — білий тризуб на прозорому тлі).
  static const String _smallIcon = 'ic_stat_xsilent';

  /// Акцентний колір банера (тон бренду з теми застосунку).
  static const Color _accent = Color(0xFF3F5C78);

  /// Ідентифікатори кнопок на банері сповіщення.
  static const String actionOkId = 'ok';
  static const String actionSnoozeId = 'snooze';

  /// На скільки «Відкласти» переносить нагадування.
  static const Duration snoozeDelay = Duration(minutes: 5);

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone.identifier));

    const android = AndroidInitializationSettings(_smallIcon);
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: notificationActionCallback,
      onDidReceiveBackgroundNotificationResponse: notificationActionCallback,
    );

    final android0 = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android0 != null) {
      await android0.createNotificationChannel(_silenceChannel);
      await android0.createNotificationChannel(_customChannel);
      await android0.createNotificationChannel(_spokenChannel);
      // Прибрати канали зі старих версій застосунку.
      await android0.deleteNotificationChannel(channelId: _legacyChannelId);
      await android0.deleteNotificationChannel(channelId: _legacySpokenChannelId);
    }
  }

  /// Канал з версій до розділення на два — видаляється під час [init].
  static const String _legacyChannelId = 'reminders';

  /// Запитує дозволи на сповіщення (і точні будильники на Android 12+).
  /// Повертає `true`, якщо сповіщення дозволені.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
      return granted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    return true;
  }

  /// Приводить заплановані сповіщення нагадування у відповідність до його стану.
  Future<void> sync(Reminder reminder) async {
    await cancel(reminder.id);
    if (!reminder.enabled) return;

    final body = reminder.body?.trim();
    for (final weekday in Weekdays.toWeekdays(reminder.weekdayMask)) {
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.id, weekday),
        title: reminder.title,
        body: (body != null && body.isNotEmpty) ? body : null,
        scheduledDate: _nextInstanceOf(reminder.hour, reminder.minute, weekday),
        notificationDetails: _detailsFor(
          isBuiltIn: reminder.isBuiltIn,
          speakAloud: reminder.speakAloud,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: _encodePayload(reminder),
      );
    }
  }

  Future<void> syncAll(Iterable<Reminder> reminders) async {
    for (final reminder in reminders) {
      await sync(reminder);
    }
  }

  /// Скасовує всі сповіщення нагадування (щотижневі + відкладене).
  Future<void> cancel(int reminderId) async {
    await _plugin.cancel(id: snoozeNotificationId(reminderId));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(reminderId, weekday));
    }
  }

  // Унікальний id сповіщення: reminderId*8 + weekday (weekday 1..7).
  // weekday 0 зарезервовано під «відкладене» сповіщення (див. [snoozeNotificationId]).
  int _notificationId(int reminderId, int weekday) => reminderId * 8 + weekday;

  static int snoozeNotificationId(int reminderId) => reminderId * 8;

  static NotificationDetails _detailsFor({
    required bool isBuiltIn,
    required bool speakAloud,
  }) {
    // Озвучені нагадування: канал грає короткий гонг, потім (з паузою у
    // [gongLeadIn]) фоновий ізолят проговорює текст — без накладання.
    final AndroidNotificationChannel channel = speakAloud
        ? _spokenChannel
        : (isBuiltIn ? _silenceChannel : _customChannel);
    final urgent = isBuiltIn || speakAloud;
    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction(actionOkId, 'Гаразд',
          cancelNotification: true),
      // «Відкласти» — лише для власних нагадувань, не для «Хвилини мовчання».
      if (!isBuiltIn)
        const AndroidNotificationAction(actionSnoozeId, 'Відкласти',
            cancelNotification: true),
    ];
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: _smallIcon,
        color: _accent,
        importance: channel.importance,
        priority: urgent ? Priority.max : Priority.high,
        playSound: channel.playSound,
        sound: channel.sound,
        category: AndroidNotificationCategory.reminder,
        actions: actions,
      ),
      iOS: DarwinNotificationDetails(
        // Гонг для iOS ще не вшито в бандл — поки без звуку для озвучених.
        presentSound: !speakAloud,
        interruptionLevel: urgent
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  static String _encodePayload(Reminder reminder) => jsonEncode({
        'id': reminder.id,
        'builtIn': reminder.isBuiltIn,
        'speak': reminder.speakAloud,
        'title': reminder.title,
        'body': reminder.body,
      });

  /// Переносить нагадування на [snoozeDelay]: показує гонг-сповіщення знову
  /// і (для озвучених) планує повторне озвучення. Викликається з обробника
  /// натискання кнопки «Відкласти» — можливо, у фоновому ізоляті.
  Future<void> snooze(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id == null) return;
    final isBuiltIn = payload['builtIn'] == true;
    final speakAloud = payload['speak'] == true;
    final title = (payload['title'] as String?) ?? 'Нагадування';
    final body = (payload['body'] as String?)?.trim();

    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    final when = tz.TZDateTime.now(tz.local).add(snoozeDelay);

    await _plugin.zonedSchedule(
      id: snoozeNotificationId(id),
      title: title,
      body: (body != null && body.isNotEmpty) ? body : null,
      scheduledDate: when,
      notificationDetails:
          _detailsFor(isBuiltIn: isBuiltIn, speakAloud: speakAloud),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(payload),
    );

    if (speakAloud && body != null && body.isNotEmpty) {
      await armSnoozeAlarm(id, when);
    }
  }

  /// Пауза перед озвученням: час, за який відіграє гонг каналу `spoken_reminders_v2`
  /// (`res/raw/gong.wav` ≈ 1.4 с). Використовується фоновим ізолятом аларму.
  static const Duration gongLeadIn = Duration(milliseconds: 1500);

  tz.TZDateTime _nextInstanceOf(int hour, int minute, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Обробник натискання кнопок на банері сповіщення. Реєструється в
/// [NotificationService.init] і як foreground-, і як background-callback
/// (для останнього має бути топ-рівневою функцією з `@pragma`).
@pragma('vm:entry-point')
Future<void> notificationActionCallback(NotificationResponse response) async {
  // «Гаразд» лише прибирає сповіщення (cancelNotification: true) — коду не треба.
  if (response.actionId != NotificationService.actionSnoozeId) return;

  final raw = response.payload;
  if (raw == null || raw.isEmpty) return;
  try {
    // Обробник може працювати у власному фоновому ізоляті — підключити плагіни.
    DartPluginRegistrant.ensureInitialized();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    await NotificationService().snooze(payload);
  } catch (_) {
    // Некоректний payload — просто ігноруємо.
  }
}
