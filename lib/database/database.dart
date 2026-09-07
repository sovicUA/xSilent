import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/weekdays.dart';

part 'database.g.dart';

/// Нагадування «Хвилина мовчання».
///
/// Одне вбудоване нагадування ([isBuiltIn] == true) створюється під час першого
/// запуску (щодня о 9:00). Користувач може додавати власні.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Текст тіла сповіщення. `null`/порожній — показувати лише [title].
  TextColumn get body => text().nullable()();

  /// Година спрацювання, 0–23.
  IntColumn get hour => integer()();

  /// Хвилина спрацювання, 0–59.
  IntColumn get minute => integer()();

  /// Бітова маска днів тижня, див. [Weekdays].
  IntColumn get weekdayMask => integer().withDefault(const Constant(Weekdays.everyDay))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Чи проговорювати текст сповіщення вголос (TTS) при спрацюванні.
  BoolColumn get speakAloud => boolean().withDefault(const Constant(true))();

  /// Гучність озвучення саме цього нагадування, 0.0–1.0.
  RealColumn get announcementVolume =>
      real().withDefault(const Constant(1.0))();

  /// Лише для вбудованого нагадування: чи програвати цокання метронома
  /// протягом хвилини мовчання (вбудовується у звук каналу оголошення).
  BoolColumn get tickDuringSilence =>
      boolean().withDefault(const Constant(false))();

  /// Чи давати попередній сигнал (гонг) за [preLeadSeconds] до спрацювання.
  /// За замовчуванням вимкнено; для вбудованого нагадування вмикається явно.
  BoolColumn get preNotify => boolean().withDefault(const Constant(false))();

  /// За скільки секунд до нагадування давати попередній сигнал (5–60, крок 5).
  IntColumn get preLeadSeconds => integer().withDefault(const Constant(10))();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'xsilent'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(reminders, reminders.body);
          }
          if (from < 3) {
            await m.addColumn(reminders, reminders.speakAloud);
          }
          if (from < 4) {
            await m.addColumn(reminders, reminders.announcementVolume);
          }
          if (from < 5) {
            await m.addColumn(reminders, reminders.tickDuringSilence);
          }
          if (from < 6) {
            await m.addColumn(reminders, reminders.preNotify);
            await m.addColumn(reminders, reminders.preLeadSeconds);
            // Наявне вбудоване нагадування досі мало жорстко зашитий
            // попередній сигнал за 10 с — зберігаємо цю поведінку.
            await customStatement(
              'UPDATE reminders SET pre_notify = 1 WHERE is_built_in = 1',
            );
          }
        },
      );
}
