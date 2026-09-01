import 'dart:convert';
import 'dart:ui' show Color, DartPluginRegistrant, Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/weekdays.dart';
import 'announcement_service.dart';
import 'sound_store.dart';

/// Планування локальних сповіщень для нагадувань.
///
/// Озвучення роблять «звуком каналу»: при збереженні нагадування
/// [AnnouncementService] синтезує аудіофайл «гонг + текст» і кладе його в
/// MediaStore; канал `spoken_r{id}_{hash}` вказує на цей файл. Систе­ма
/// відтворює звук каналу незалежно від фонових обмежень застосунку.
class NotificationService {
  NotificationService({
    required this.l10n,
    FlutterLocalNotificationsPlugin? plugin,
    AnnouncementService? announcements,
    SoundStore? soundStore,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _announcements = announcements ?? AnnouncementService(),
        _sound = soundStore ?? const SoundStore();

  final L10n l10n;
  final FlutterLocalNotificationsPlugin _plugin;
  final AnnouncementService _announcements;
  final SoundStore _sound;

  static const String _spokenGroupId = 'spoken_group';
  static const String silenceChannelId = 'moment_of_silence_v2';
  static const String customChannelId = 'custom_reminders_v2';
  static const String mosPreChannelId = 'mos_pre';
  static const String mosEndChannelId = 'mos_end';

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
  static const Duration _preLead = Duration(seconds: 10);
  static const Duration _silenceLength = Duration(minutes: 1);
  static const int _preIdBase = 8000000;
  static const int _endIdBase = 8100000;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  AndroidNotificationChannel get _silenceChannel => AndroidNotificationChannel(
        silenceChannelId,
        l10n.chanSilenceName,
        description: l10n.chanSilenceDesc,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('main_gong'),
      );

  AndroidNotificationChannel get _customChannel => AndroidNotificationChannel(
        customChannelId,
        l10n.chanCustomName,
        description: l10n.chanCustomDesc,
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('additional_gong'),
      );

  AndroidNotificationChannel get _mosPreChannel => AndroidNotificationChannel(
        mosPreChannelId,
        l10n.chanPreName,
        description: l10n.chanPreDesc,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('additional_gong'),
      );

  AndroidNotificationChannel get _mosEndChannel => AndroidNotificationChannel(
        mosEndChannelId,
        l10n.chanEndName,
        description: l10n.chanEndDesc,
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('main_gong'),
      );

  /// Мінімальна ініціалізація, потрібна й у фоновому ізоляті (кнопка
  /// «Відкласти»): таймзони + сам плагін. Канали тут не чіпаємо — їх створює
  /// застосунок на передньому плані у [init].
  Future<void> _initCore() async {
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
  }

  Future<void> init() async {
    await _initCore();

    final android0 = _android;
    if (android0 != null) {
      await android0.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(_spokenGroupId, l10n.spokenGroupName),
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
      // Точні будильники надає декларація `USE_EXACT_ALARM` у маніфесті
      // (застосунок-нагадування — дозволений кейс). Запит через систему
      // потрібен лише як запасний варіант, коли її все ж немає — інакше
      // `requestExactAlarmsPermission` кидало б у налаштування на кожен старт.
      if (!(await android.canScheduleExactNotifications() ?? true)) {
        await android.requestExactAlarmsPermission();
      }
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
    await _cancelNotifications(reminder.id, isBuiltIn: reminder.isBuiltIn);

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
      channelName = l10n.spokenChannelName(reminder.title);
      try {
        final existing = await _android?.getNotificationChannels() ?? [];
        if (existing.any((c) => c.id == targetId)) {
          channelId = targetId;
          // Прибрати озвучення інших мов / версій цього нагадування, що
          // лишилися після зміни мови чи тексту.
          await _pruneSpoken(reminder.id, keepChannelId: channelId);
          await _sound.pruneExcept(
            _announcements.soundPrefix(reminder.id),
            _announcements.soundName(reminder.id, body, volume, gong),
          );
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
              description: l10n.spokenChannelDesc(reminder.title),
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
        (channelId, channelName) = _fallbackChannel(reminder);
      }
    } else {
      await _purgeSpoken(reminder.id);
      (channelId, channelName) = _fallbackChannel(reminder);
    }

    final details = _detailsFor(
      channelId: channelId,
      channelName: channelName,
      actions: _reminderActions(isBuiltIn: reminder.isBuiltIn),
    );
    final payload = _encodePayload(reminder, channelId);

    for (final weekday in Weekdays.toWeekdays(reminder.weekdayMask)) {
      final at = nextInstanceOf(
        tz.TZDateTime.now(tz.local),
        reminder.hour,
        reminder.minute,
        weekday,
      );
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
          title: l10n.preNotifTitle,
          body: null,
          scheduledDate: at.subtract(_preLead),
          notificationDetails: _detailsFor(
            channelId: mosPreChannelId,
            channelName: l10n.chanPreName,
            actions: [
              AndroidNotificationAction(actionOkId, l10n.actionOk,
                  cancelNotification: true),
            ],
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        await _plugin.zonedSchedule(
          id: _endIdBase + weekday,
          title: l10n.endNotifTitle,
          body: null,
          scheduledDate: at.add(_silenceLength),
          notificationDetails: _detailsFor(
            channelId: mosEndChannelId,
            channelName: l10n.chanEndName,
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

  (String, String) _fallbackChannel(Reminder reminder) => reminder.isBuiltIn
      ? (silenceChannelId, l10n.chanSilenceName)
      : (customChannelId, l10n.chanCustomName);

  List<AndroidNotificationAction> _reminderActions({required bool isBuiltIn}) => [
        AndroidNotificationAction(actionOkId, l10n.actionOk,
            cancelNotification: true),
        if (!isBuiltIn)
          AndroidNotificationAction(actionSnoozeId, l10n.actionSnooze,
              cancelNotification: true),
      ];

  /// Повністю прибирає нагадування: сповіщення, канали озвучення, аудіофайли.
  Future<void> purge(int reminderId, {bool isBuiltIn = false}) async {
    await _cancelNotifications(reminderId, isBuiltIn: isBuiltIn);
    await _purgeSpoken(reminderId);
  }

  /// Скасовує заплановані сповіщення нагадування. Сповіщення послідовності
  /// «хвилини мовчання» (pre/end) мають глобальні id, тож чіпаємо їх лише для
  /// вбудованого нагадування — інакше синхронізація будь-якого власного
  /// нагадування скасувала б попередження й сигнал завершення.
  Future<void> _cancelNotifications(
    int reminderId, {
    required bool isBuiltIn,
  }) async {
    await _plugin.cancel(id: snoozeNotificationId(reminderId));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(reminderId, weekday));
      if (isBuiltIn) {
        await _plugin.cancel(id: _preIdBase + weekday);
        await _plugin.cancel(id: _endIdBase + weekday);
      }
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

  String _encodePayload(Reminder reminder, String channelId) => jsonEncode({
        'id': reminder.id,
        'builtIn': reminder.isBuiltIn,
        'title': reminder.title,
        'body': reminder.body,
        'channel': channelId,
        'locale': l10n.localeName,
      });

  /// Переносить нагадування на [snoozeDelay]: показує те саме сповіщення знову.
  ///
  /// Викликається з фонового ізоляту (обробник кнопки банера), тож спершу
  /// ініціалізує плагін і таймзони — інакше [FlutterLocalNotificationsPlugin]
  /// не має контексту й [zonedSchedule] тихо нічого не робить.
  Future<void> snooze(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id == null) return;
    final isBuiltIn = payload['builtIn'] == true;
    final title = (payload['title'] as String?) ?? l10n.reminderFallbackTitle;
    final body = (payload['body'] as String?)?.trim();
    final channelId = (payload['channel'] as String?) ??
        (isBuiltIn ? silenceChannelId : customChannelId);

    await _initCore();

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

}

/// Найближчий момент **строго після** [now], що збігається за днем тижня
/// ([DateTime.weekday]: 1 = понеділок … 7 = неділя) та за годиною/хвилиною.
///
/// Винесено з класу для юніт-тестів (це логіка, яку реально використовує
/// планувальник — не плутати з утилітами, що були в `utils/`).
@visibleForTesting
tz.TZDateTime nextInstanceOf(
  tz.TZDateTime now,
  int hour,
  int minute,
  int weekday,
) {
  var scheduled =
      tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
  while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
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
    final locale = Locale((payload['locale'] as String?) ?? 'uk');
    await NotificationService(l10n: lookupL10n(locale)).snooze(payload);
  } catch (_) {
    // Некоректний payload — просто ігноруємо.
  }
}
