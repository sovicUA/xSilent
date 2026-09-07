import 'package:drift/drift.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/weekdays.dart';
import '../services/notification_service.dart';

/// Єдина точка доступу до нагадувань: усі зміни в БД одразу
/// синхронізуються зі сповіщеннями (і генерацією озвучення).
class RemindersRepository {
  RemindersRepository(this._db, this._notifications, this._l10n);

  final AppDatabase _db;
  final NotificationService _notifications;
  final L10n _l10n;

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

  /// Значення `builtInTitle` / `builtInAnnouncement` для всіх підтримуваних мов —
  /// щоб відрізнити «дефолтний» текст вбудованого нагадування від правки користувача.
  static Iterable<L10n> _allLocales() =>
      L10n.supportedLocales.map((l) => lookupL10n(l));

  static Set<String> _defaultTitles() =>
      _allLocales().map((l) => l.builtInTitle).toSet();
  static Set<String> _defaultBodies() =>
      _allLocales().map((l) => l.builtInAnnouncement).toSet();

  /// Приводить БД і заплановані сповіщення у відповідність до поточної мови:
  /// створює вбудоване нагадування (щодня о 9:00), якщо база порожня;
  /// перелокалізовує його назву/тіло, якщо їх не редагували; перестворює канали
  /// й переплановує сповіщення. Викликається на старті та після кожної зміни
  /// мови (виклики серіалізуються в `main`).
  Future<void> reconcile() async {
    // Плагін і таймзони мають бути готові до першого `sync()` нижче (через
    // `create()` чи `syncAll()`). `init()` також перестворює канали з
    // локалізованими назвами — тож викликається й після зміни мови.
    await _notifications.init();

    final existing = await _db.select(_db.reminders).get();

    if (existing.isEmpty) {
      // `create()` сам викликає `sync()` для щойно створеного нагадування.
      await create(
        title: _l10n.builtInTitle,
        body: _l10n.builtInAnnouncement,
        hour: 9,
        minute: 0,
        weekdayMask: Weekdays.everyDay,
        isBuiltIn: true,
      );
      return;
    }

    for (final reminder in existing) {
      if (!reminder.isBuiltIn) continue;
      var patch = const RemindersCompanion();
      if (_defaultTitles().contains(reminder.title)) {
        patch = patch.copyWith(title: Value(_l10n.builtInTitle));
      }
      // Бекфіл тіла для баз зі старих схем + перелокалізація дефолтного тексту.
      if (_normalize(reminder.body) == null ||
          _defaultBodies().contains(reminder.body)) {
        patch = patch.copyWith(body: Value(_l10n.builtInAnnouncement));
      }
      if (patch != const RemindersCompanion()) {
        await (_db.update(_db.reminders)..where((t) => t.id.equals(reminder.id)))
            .write(patch);
      }
    }

    await _notifications.syncAll(await _db.select(_db.reminders).get());

    // Другий прохід: тепер, коли всі сповіщення зі старими id скасовано,
    // остаточно прибрати застарілі канали, які плагін міг перестворити при
    // переплануванні збережених сповіщень (напр. після оновлення пакета).
    await _notifications.sweepLegacyChannels();
  }

  Future<Reminder> create({
    required String title,
    required String? body,
    required int hour,
    required int minute,
    required int weekdayMask,
    bool speakAloud = true,
    double announcementVolume = 1.0,
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
            announcementVolume: Value(announcementVolume),
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
    required bool speakAloud,
    required double announcementVolume,
  }) async {
    final updated = reminder.copyWith(
      title: title,
      body: Value(_normalize(body)),
      hour: hour,
      minute: minute,
      weekdayMask: weekdayMask,
      speakAloud: speakAloud,
      announcementVolume: announcementVolume,
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
    await _notifications.purge(reminder.id, isBuiltIn: reminder.isBuiltIn);
  }
}
