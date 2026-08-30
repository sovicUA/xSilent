import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database.dart';
import '../models/weekdays.dart';

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

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone.identifier));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    final android0 = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android0 != null) {
      await android0.createNotificationChannel(_silenceChannel);
      await android0.createNotificationChannel(_customChannel);
      // Прибрати єдиний канал зі старих версій застосунку.
      await android0.deleteNotificationChannel(channelId: _legacyChannelId);
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
        notificationDetails: _detailsFor(reminder),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> syncAll(Iterable<Reminder> reminders) async {
    for (final reminder in reminders) {
      await sync(reminder);
    }
  }

  /// Скасовує всі сповіщення нагадування (для всіх днів тижня).
  Future<void> cancel(int reminderId) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(reminderId, weekday));
    }
  }

  // Унікальний id сповіщення: reminderId*8 + weekday (weekday 1..7).
  int _notificationId(int reminderId, int weekday) => reminderId * 8 + weekday;

  NotificationDetails _detailsFor(Reminder reminder) {
    final channel = reminder.isBuiltIn ? _silenceChannel : _customChannel;
    final urgent = reminder.isBuiltIn;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: urgent ? Priority.max : Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: urgent
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

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
