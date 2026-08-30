import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../services/notification_service.dart';

/// Єдина точка доступу до нагадувань: усі зміни в БД одразу
/// синхронізуються з запланованими сповіщеннями.
class RemindersRepository {
  RemindersRepository(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

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
    await _notifications.syncAll(await _db.select(_db.reminders).get());
  }

  Future<Reminder> create({
    required String title,
    required String? body,
    required int hour,
    required int minute,
    required int weekdayMask,
    bool isBuiltIn = false,
  }) async {
    final reminder = await _db.into(_db.reminders).insertReturning(
          RemindersCompanion.insert(
            title: title,
            body: Value(_normalize(body)),
            hour: hour,
            minute: minute,
            weekdayMask: Value(weekdayMask),
            isBuiltIn: Value(isBuiltIn),
          ),
        );
    await _notifications.sync(reminder);
    return reminder;
  }

  Future<void> update(
    Reminder reminder, {
    required String title,
    required String? body,
    required int hour,
    required int minute,
    required int weekdayMask,
  }) async {
    final updated = reminder.copyWith(
      title: title,
      body: Value(_normalize(body)),
      hour: hour,
      minute: minute,
      weekdayMask: weekdayMask,
    );
    await _db.update(_db.reminders).replace(updated);
    await _notifications.sync(updated);
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
  }

  Future<void> delete(Reminder reminder) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(reminder.id)))
        .go();
    await _notifications.cancel(reminder.id);
  }
}
