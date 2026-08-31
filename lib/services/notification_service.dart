import 'dart:convert';
import 'dart:ui' show Color, DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database.dart';
import '../models/weekdays.dart';
import 'announcement_service.dart';
import 'sound_store.dart';

/// Планування локальних сповіщень для нагадувань.
///
/// Озвучення роблять «звуком каналу»: при збереженні нагадування
/// [AnnouncementService] синтезує аудіофайл «гонг + текст» і кладе його в
/// MediaStore; канал `spoken_r{id}_{hash}` вказує на цей файл. Систе­ма
/// відтворює звук каналу незалежно від фонових обмежень застосунку.
///
/// Щотижневий повтор — вбудований у `zonedSchedule`
/// (`DateTimeComponents.dayOfWeekAndTime`), переживає перезавантаження.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    AnnouncementService? announcements,
    SoundStore? soundStore,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _announcements = announcements ?? AnnouncementService(),
        _sound = soundStore ?? const SoundStore();

  final FlutterLocalNotificationsPlugin _plugin;
  final AnnouncementService _announcements;
  final SoundStore _sound;

  static const String _spokenGroupId = 'spoken_group';

  /// Вбудоване нагадування без озвучення — основний гонг.
  static const AndroidNotificationChannel _silenceChannel =
      AndroidNotificationChannel(
    'moment_of_silence_v2',
    'Хвилина мовчання',
    description: 'Загальнонаціональна хвилина мовчання',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('main_gong'),
  );

  /// Власні нагадування без озвучення — додатковий гонг.
  static const AndroidNotificationChannel _customChannel =
      AndroidNotificationChannel(
    'custom_reminders_v2',
    'Власні нагадування',
    description: 'Нагадування, які ви додали самостійно',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('additional_gong'),
  );

  /// Попереднє сповіщення за 10 с до хвилини мовчання — додатковий гонг.
  static const AndroidNotificationChannel _mosPreChannel =
      AndroidNotificationChannel(
    'mos_pre',
    'Хвилина мовчання — попередження',
    description: 'Сповіщення за 10 секунд до хвилини мовчання',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('additional_gong'),
  );

  /// Сповіщення про завершення хвилини мовчання — основний гонг.
  static const AndroidNotificationChannel _mosEndChannel =
      AndroidNotificationChannel(
    'mos_end',
    'Хвилина мовчання — завершення',
    description: 'Сигнал про завершення хвилини мовчання',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('main_gong'),
  );

  /// Канали зі старих версій застосунку — видаляються в [init].
  static const List<String> _legacyChannelIds = [
    'reminders',
    'spoken_reminders',
    'spoken_reminders_v2',
    'moment_of_silence',
    'custom_reminders',
  ];

  static const String _smallIcon = 'ic_stat_xsilent';
  static const Color _accent = Color(0xFF3F5C78);

  static const String actionOkId = 'ok';
  static const String actionSnoozeId = 'snooze';

  static const Duration snoozeDelay = Duration(minutes: 5);

  /// За скільки до хвилини мовчання показувати попереднє сповіщення.
  static const Duration _preLead = Duration(seconds: 10);

  /// Тривалість хвилини мовчання — через цей час грає основний гонг «кінець».
  static const Duration _silenceLength = Duration(minutes: 1);

  static const int _preIdBase = 8000000;
  static const int _endIdBase = 8100000;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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

    final android0 = _android;
    if (android0 != null) {
      await android0.createNotificationChannelGroup(
        const AndroidNotificationChannelGroup(
          _spokenGroupId,
          'Озвучені нагадування',
        ),
      );
      for (final ch in [
        _silenceChannel,
        _customChannel,
        _mosPreChannel,
        _mosEndChannel,
      ]) {
        await android0.createNotificationChannel(ch);
      }
      for (final id in _legacyChannelIds) {
        await android0.deleteNotificationChannel(channelId: id);
      }
    }
  }

  Future<bool> requestPermissions() async {
    final android = _android;
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
    await _cancelNotifications(reminder.id);

    if (!reminder.enabled) {
      await _purgeSpoken(reminder.id);
      return;
    }

    final body = reminder.body?.trim();
    final spoken = reminder.speakAloud && body != null && body.isNotEmpty;
    final gong = reminder.isBuiltIn ? Gong.main : Gong.additional;

    String channelId;
    String channelName;
    if (spoken) {
      final volume = reminder.announcementVolume.clamp(0.0, 1.0);
      final targetId = _announcements.channelId(reminder.id, body, volume, gong);
      channelName = 'Озвучення: ${reminder.title}';
      try {
        final existing = await _android?.getNotificationChannels() ?? [];
        if (existing.any((c) => c.id == targetId)) {
          channelId = targetId; // текст/гучність незмінні — канал актуальний
        } else {
          final result = await _announcements.build(
            reminderId: reminder.id,
            text: body,
            volume: volume,
            gong: gong,
          );
          channelId = result.channelId;
          await _android?.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              channelName,
              description: 'Озвучене нагадування «${reminder.title}»',
              groupId: _spokenGroupId,
              importance: Importance.max,
              sound: UriAndroidNotificationSound(result.contentUri),
            ),
          );
          await _pruneSpoken(reminder.id, keepChannelId: channelId);
          await _sound.pruneExcept(
            _announcements.soundPrefix(reminder.id),
            result.soundName,
          );
        }
      } on AnnouncementException catch (e) {
        debugPrint('Озвучення не згенеровано (${reminder.id}): ${e.message}');
        await _purgeSpoken(reminder.id);
        channelId = _fallbackChannel(reminder).id;
        channelName = _fallbackChannel(reminder).name;
      }
    } else {
      await _purgeSpoken(reminder.id);
      channelId = _fallbackChannel(reminder).id;
      channelName = _fallbackChannel(reminder).name;
    }

    final details = _detailsFor(
      channelId: channelId,
      channelName: channelName,
      actions: _reminderActions(isBuiltIn: reminder.isBuiltIn),
    );
    final payload = _encodePayload(reminder, channelId);

    for (final weekday in Weekdays.toWeekdays(reminder.weekdayMask)) {
      final at = _nextInstanceOf(reminder.hour, reminder.minute, weekday);
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.id, weekday),
        title: reminder.title,
        body: (body != null && body.isNotEmpty) ? body : null,
        scheduledDate: at,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );

      if (reminder.isBuiltIn) {
        await _plugin.zonedSchedule(
          id: _preIdBase + weekday,
          title: 'Нагадування про хвилину мовчання',
          body: null,
          scheduledDate: at.subtract(_preLead),
          notificationDetails: _detailsFor(
            channelId: _mosPreChannel.id,
            channelName: _mosPreChannel.name,
            actions: const [
              AndroidNotificationAction(actionOkId, 'Гаразд',
                  cancelNotification: true),
            ],
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        await _plugin.zonedSchedule(
          id: _endIdBase + weekday,
          title: 'Хвилину мовчання завершено',
          body: null,
          scheduledDate: at.add(_silenceLength),
          notificationDetails: _detailsFor(
            channelId: _mosEndChannel.id,
            channelName: _mosEndChannel.name,
            actions: const [],
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> syncAll(Iterable<Reminder> reminders) async {
    for (final reminder in reminders) {
      await sync(reminder);
    }
  }

  AndroidNotificationChannel _fallbackChannel(Reminder reminder) =>
      reminder.isBuiltIn ? _silenceChannel : _customChannel;

  List<AndroidNotificationAction> _reminderActions({required bool isBuiltIn}) => [
        const AndroidNotificationAction(actionOkId, 'Гаразд',
            cancelNotification: true),
        if (!isBuiltIn)
          const AndroidNotificationAction(actionSnoozeId, 'Відкласти',
              cancelNotification: true),
      ];

  /// Повністю прибирає нагадування: сповіщення, канали озвучення, аудіофайли.
  Future<void> purge(int reminderId) async {
    await _cancelNotifications(reminderId);
    await _purgeSpoken(reminderId);
  }

  Future<void> _cancelNotifications(int reminderId) async {
    await _plugin.cancel(id: snoozeNotificationId(reminderId));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(reminderId, weekday));
      // Додаткові сповіщення хвилини мовчання (лише для вбудованого) —
      // скасовувати завжди, зайвий cancel нешкідливий.
      await _plugin.cancel(id: _preIdBase + weekday);
      await _plugin.cancel(id: _endIdBase + weekday);
    }
  }

  Future<void> _purgeSpoken(int reminderId) async {
    await _pruneSpoken(reminderId, keepChannelId: null);
    await _sound.deleteAll(_announcements.soundPrefix(reminderId));
  }

  Future<void> _pruneSpoken(int reminderId, {String? keepChannelId}) async {
    final android0 = _android;
    if (android0 == null) return;
    final prefix = _announcements.channelPrefix(reminderId);
    final channels = await android0.getNotificationChannels() ?? [];
    for (final ch in channels) {
      if (ch.id.startsWith(prefix) && ch.id != keepChannelId) {
        await android0.deleteNotificationChannel(channelId: ch.id);
      }
    }
  }

  int _notificationId(int reminderId, int weekday) => reminderId * 8 + weekday;

  static int snoozeNotificationId(int reminderId) => reminderId * 8;

  NotificationDetails _detailsFor({
    required String channelId,
    required String channelName,
    required List<AndroidNotificationAction> actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        icon: _smallIcon,
        color: _accent,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        actions: actions,
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  static String _encodePayload(Reminder reminder, String channelId) =>
      jsonEncode({
        'id': reminder.id,
        'builtIn': reminder.isBuiltIn,
        'title': reminder.title,
        'body': reminder.body,
        'channel': channelId,
      });

  /// Переносить нагадування на [snoozeDelay]: показує те саме сповіщення знову.
  Future<void> snooze(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id == null) return;
    final isBuiltIn = payload['builtIn'] == true;
    final title = (payload['title'] as String?) ?? 'Нагадування';
    final body = (payload['body'] as String?)?.trim();
    final channelId = (payload['channel'] as String?) ??
        (isBuiltIn ? _silenceChannel.id : _customChannel.id);

    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.zonedSchedule(
      id: snoozeNotificationId(id),
      title: title,
      body: (body != null && body.isNotEmpty) ? body : null,
      scheduledDate: tz.TZDateTime.now(tz.local).add(snoozeDelay),
      notificationDetails: _detailsFor(
        channelId: channelId,
        channelName: title,
        actions: _reminderActions(isBuiltIn: isBuiltIn),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(payload),
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

/// Обробник натискання кнопок на банері сповіщення.
@pragma('vm:entry-point')
Future<void> notificationActionCallback(NotificationResponse response) async {
  if (response.actionId != NotificationService.actionSnoozeId) return;

  final raw = response.payload;
  if (raw == null || raw.isEmpty) return;
  try {
    DartPluginRegistrant.ensureInitialized();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    await NotificationService().snooze(payload);
  } catch (_) {
    // Некоректний payload — просто ігноруємо.
  }
}
