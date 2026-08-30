import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../services/notification_service.dart';
import '../services/speech_alarm.dart';

/// Єдина точка доступу до нагадувань: усі зміни в БД одразу
/// синхронізуються з запланованими сповіщеннями та alarm-ами озвучення.
class RemindersRepository {
  RemindersRepository(this._db, this._notifications, this._alarms);

  final AppDatabase _db;
  final NotificationService _notifications;
  final SpeechAlarmScheduler _alarms;

  Stream<List<Reminder>> watchAll() {
    return (_db.select(_db.reminders)
          ..orderBy([
            (t) => OrderingTerm(expression: t.hour),
            (t) => OrderingTerm(expression: t.minute),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Future<Reminder> getById(int id) {
    return (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  static const String _builtInBody =
      'УВАГА! Оголошується загальнонаціональна хвилина мовчання.';

  /// Створює вбудоване нагадування (щодня о 9:00), якщо база порожня.
  /// Для баз зі схеми v1 (де ще не було колонки `body`) — заповнює тіло
  /// вбудованого нагадування.
  Future<void> seedDefaultIfEmpty() async {
    final existing = await _db.select(_db.reminders).get();
    if (existing.isEmpty) {
      await create(
        title: 'Хвилина мовчання',
        body: _builtInBody,
        hour: 9,
        minute: 0,
        weekdayMask: Weekdays.everyDay,
        isBuiltIn: true,
      );
      return;
    }

    for (final reminder in existing) {
      if (reminder.isBuiltIn && _normalize(reminder.body) == null) {
        await (_db.update(_db.reminders)..where((t) => t.id.equals(reminder.id)))
            .write(const RemindersCompanion(body: Value(_builtInBody)));
      }
    }
    final all = await _db.select(_db.reminders).get();
    await _notifications.syncAll(all);
    await _alarms.armAll(all);
  }

  Future<Reminder> create({
    required String title,
    required String? body,
    required int hour,
    required int minute,
    required int weekdayMask,
    bool speakAloud = true,
    bool isBuiltIn = false,
  }) async {
    final reminder = await _db.into(_db.reminders).insertReturning(
          RemindersCompanion.insert(
            title: title,
            body: Value(_normalize(body)),
            hour: hour,
            minute: minute,
            weekdayMask: Value(weekdayMask),
            speakAloud: Value(speakAloud),
            isBuiltIn: Value(isBuiltIn),
          ),
        );
    await _notifications.sync(reminder);
    await _alarms.arm(reminder);
    return reminder;
  }

  Future<void> update(
    Reminder reminder, {
    required String title,
    required String? body,
    required int hour,
    required int minute,
    required int weekdayMask,
    required bool speakAloud,
  }) async {
    final updated = reminder.copyWith(
      title: title,
      body: Value(_normalize(body)),
      hour: hour,
      minute: minute,
      weekdayMask: weekdayMask,
      speakAloud: speakAloud,
    );
    await _db.update(_db.reminders).replace(updated);
    await _notifications.sync(updated);
    await _alarms.arm(updated);
  }

  /// Порожній рядок → `null`, щоб у сповіщенні не було порожнього тіла.
  static String? _normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> setEnabled(Reminder reminder, bool enabled) async {
    final updated = reminder.copyWith(enabled: enabled);
    await _db.update(_db.reminders).replace(updated);
    await _notifications.sync(updated);
    await _alarms.arm(updated);
  }

  Future<void> delete(Reminder reminder) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(reminder.id)))
        .go();
    await _notifications.cancel(reminder.id);
    await _alarms.disarm(reminder.id);
  }
}
