// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class L10nUk extends L10n {
  L10nUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Хвилина мовчання';

  @override
  String get settingsTooltip => 'Налаштування';

  @override
  String errorPrefix(String error) {
    return 'Помилка: $error';
  }

  @override
  String get remindersSection => 'Нагадування';

  @override
  String get fabNewReminder => 'Нагадування';

  @override
  String get emptyTitle => 'Немає нагадувань';

  @override
  String get emptyBody => 'Додайте нагадування кнопкою внизу.';

  @override
  String get editorNewTitle => 'Нове нагадування';

  @override
  String get editorEditTitle => 'Редагувати';

  @override
  String get save => 'Зберегти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get delete => 'Видалити';

  @override
  String get fieldTime => 'Час';

  @override
  String get fieldName => 'Назва';

  @override
  String get fieldBody => 'Текст сповіщення';

  @override
  String get fieldBodyHelper =>
      'Необовʼязково — показується під назвою у шторці';

  @override
  String get previewTooltip => 'Прослухати';

  @override
  String get speakSwitchTitle => 'Озвучити сповіщення';

  @override
  String get speakSwitchOnHint => 'Програти «гонг + текст» при спрацюванні';

  @override
  String get speakSwitchOffHint => 'Додайте текст сповіщення, щоб увімкнути';

  @override
  String volumeLabel(int percent) {
    return 'Гучність озвучення: $percent%';
  }

  @override
  String get volumeAlarmHint =>
      'Звучить через гучність будильника пристрою — не залежить від гучності сповіщень і беззвучного режиму.';

  @override
  String get repeatTitle => 'Повторювати';

  @override
  String get repeatEveryDay => 'Щодня';

  @override
  String get repeatWeekdays => 'По буднях';

  @override
  String get repeatWeekend => 'На вихідних';

  @override
  String get repeatNever => 'Не повторюється';

  @override
  String previewTooLong(int seconds) {
    return 'Озвучення триває $seconds с. У сповіщенні воно буде обрізане до ~30 с — скоротіть текст.';
  }

  @override
  String previewFailed(String message) {
    return 'Не вдалося озвучити: $message';
  }

  @override
  String get deleteTitle => 'Видалити нагадування?';

  @override
  String deleteBody(String name) {
    return '«$name» буде видалено.';
  }

  @override
  String get newReminderDefaultName => 'Сповіщення';

  @override
  String get builtInTitle => 'Хвилина мовчання';

  @override
  String get builtInAnnouncement =>
      'УВАГА! Оголошується загальнонаціональна хвилина мовчання.';

  @override
  String get chanSilenceName => 'Хвилина мовчання';

  @override
  String get chanSilenceDesc => 'Загальнонаціональна хвилина мовчання';

  @override
  String get chanCustomName => 'Власні нагадування';

  @override
  String get chanCustomDesc => 'Нагадування, які ви додали самостійно';

  @override
  String get chanPreName => 'Хвилина мовчання — попередження';

  @override
  String get chanPreDesc => 'Сповіщення за 10 секунд до хвилини мовчання';

  @override
  String get chanEndName => 'Хвилина мовчання — завершення';

  @override
  String get chanEndDesc => 'Сигнал про завершення хвилини мовчання';

  @override
  String get spokenGroupName => 'Озвучені нагадування';

  @override
  String spokenChannelName(String title) {
    return 'Озвучення: $title';
  }

  @override
  String spokenChannelDesc(String title) {
    return 'Озвучене нагадування «$title»';
  }

  @override
  String get preNotifTitle => 'Нагадування про хвилину мовчання';

  @override
  String get endNotifTitle => 'Хвилину мовчання завершено';

  @override
  String get reminderFallbackTitle => 'Нагадування';

  @override
  String get actionOk => 'Гаразд';

  @override
  String get actionSnooze => 'Відкласти';

  @override
  String get weekdayShort1 => 'Пн';

  @override
  String get weekdayShort2 => 'Вт';

  @override
  String get weekdayShort3 => 'Ср';

  @override
  String get weekdayShort4 => 'Чт';

  @override
  String get weekdayShort5 => 'Пт';

  @override
  String get weekdayShort6 => 'Сб';

  @override
  String get weekdayShort7 => 'Нд';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get languageAuto => 'Авто (за регіоном)';

  @override
  String get languageUk => 'Українська';

  @override
  String get languageEn => 'English';
}
