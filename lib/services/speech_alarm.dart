import 'dart:io' show Platform;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../utils/next_occurrence.dart';
import 'notification_service.dart';
import 'tts_service.dart';

// Схема id аларму: reminderId * 8 + weekday. weekday 1..7 — щотижневі alarm-и
// (та сама схема, що й у NotificationService); weekday 0 — разове «відкладене»
// озвучення (не переставляється).
int _alarmId(int reminderId, int weekday) => reminderId * 8 + weekday;

/// Планує разове озвучення для відкладеного нагадування на момент [when].
Future<void> armSnoozeAlarm(int reminderId, DateTime when) async {
  if (!Platform.isAndroid) return;
  // Обробник кнопки може працювати у власному фоновому ізоляті, де плагін
  // AlarmManager ще не ініціалізований.
  await AndroidAlarmManager.initialize();
  await AndroidAlarmManager.oneShotAt(
    when,
    _alarmId(reminderId, 0),
    speechAlarmCallback,
    exact: true,
    wakeup: true,
    alarmClock: true,
    rescheduleOnReboot: false,
  );
}

/// Викликається у **власному фоновому ізоляті** плагіном AlarmManager, коли
/// настає час нагадування. Озвучує текст; для щотижневих alarm-ів переставляє
/// власний alarm на наступний тиждень, для відкладеного (weekday 0) — ні.
@pragma('vm:entry-point')
Future<void> speechAlarmCallback(int alarmId) async {
  final reminderId = alarmId ~/ 8;
  final weekday = alarmId % 8;
  final isSnooze = weekday == 0;
  if (weekday < 0 || weekday > 7) return;

  final db = AppDatabase();
  try {
    final reminder = await (db.select(db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .getSingleOrNull();

    if (reminder == null || !reminder.enabled || !reminder.speakAloud) return;
    if (!isSnooze && !Weekdays.contains(reminder.weekdayMask, weekday)) return;

    final text = reminder.body?.trim() ?? '';
    if (text.isNotEmpty) {
      final tts = FlutterTts();
      await configureTts(tts);
      // Дати відіграти гонг каналу сповіщення перед голосом (і водночас —
      // час на асинхронну ініціалізацію TTS-рушія).
      await Future<void>.delayed(NotificationService.gongLeadIn);
      await tts.speak(text, focus: true);
    }

    if (!isSnooze) {
      // Переставити на наступний тиждень (той самий день/час).
      await AndroidAlarmManager.oneShotAt(
        nextWeekdayTime(reminder.hour, reminder.minute, weekday),
        alarmId,
        speechAlarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
    }
  } finally {
    await db.close();
  }
}

/// Планує/скасовує alarm-и для озвучення нагадувань. Тільки Android —
/// на інших платформах усі методи no-op.
class SpeechAlarmScheduler {
  const SpeechAlarmScheduler();

  bool get _supported => Platform.isAndroid;

  Future<void> arm(Reminder reminder) async {
    if (!_supported) return;
    await disarm(reminder.id);
    if (!reminder.enabled || !reminder.speakAloud) return;

    for (final weekday in Weekdays.toWeekdays(reminder.weekdayMask)) {
      await AndroidAlarmManager.oneShotAt(
        nextWeekdayTime(reminder.hour, reminder.minute, weekday),
        _alarmId(reminder.id, weekday),
        speechAlarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
    }
  }

  Future<void> disarm(int reminderId) async {
    if (!_supported) return;
    // 0 — можливе відкладене озвучення, 1..7 — щотижневі.
    for (var weekday = 0; weekday <= 7; weekday++) {
      await AndroidAlarmManager.cancel(_alarmId(reminderId, weekday));
    }
  }

  Future<void> armAll(Iterable<Reminder> reminders) async {
    if (!_supported) return;
    for (final reminder in reminders) {
      await arm(reminder);
    }
  }
}
