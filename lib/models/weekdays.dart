import '../l10n/app_localizations.dart';

/// Дні тижня зберігаються як бітова маска.
///
/// Біт `weekday - 1` відповідає дню за нумерацією [DateTime.weekday]
/// (1 = понеділок … 7 = неділя). Маска 0 означає "жодного дня",
/// [Weekdays.everyDay] (== 127) — щодня.
abstract final class Weekdays {
  static const int everyDay = 127;

  static int _bit(int weekday) => 1 << (weekday - 1);

  static bool contains(int mask, int weekday) => mask & _bit(weekday) != 0;

  static int toggle(int mask, int weekday) => mask ^ _bit(weekday);

  /// Список днів ([DateTime.weekday]), увімкнених у масці, у порядку Пн→Нд.
  static List<int> toWeekdays(int mask) => [
        for (var weekday = 1; weekday <= 7; weekday++)
          if (contains(mask, weekday)) weekday,
      ];

  /// Короткий підпис дня (`weekday` 1..7).
  static String shortLabel(L10n l10n, int weekday) => switch (weekday) {
        1 => l10n.weekdayShort1,
        2 => l10n.weekdayShort2,
        3 => l10n.weekdayShort3,
        4 => l10n.weekdayShort4,
        5 => l10n.weekdayShort5,
        6 => l10n.weekdayShort6,
        _ => l10n.weekdayShort7,
      };

  /// Людиночитний опис набору днів для списку нагадувань.
  static String describe(int mask, L10n l10n) {
    final days = toWeekdays(mask);
    if (days.isEmpty) return l10n.repeatNever;
    if (days.length == 7) return l10n.repeatEveryDay;
    if (days.length == 5 &&
        !contains(mask, DateTime.saturday) &&
        !contains(mask, DateTime.sunday)) {
      return l10n.repeatWeekdays;
    }
    if (days.length == 2 &&
        contains(mask, DateTime.saturday) &&
        contains(mask, DateTime.sunday)) {
      return l10n.repeatWeekend;
    }
    return days.map((d) => shortLabel(l10n, d)).join(', ');
  }
}
