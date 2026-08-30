/// Дні тижня зберігаються як бітова маска.
///
/// Біт `weekday - 1` відповідає дню за нумерацією [DateTime.weekday]
/// (1 = понеділок … 7 = неділя). Маска 0 означає "жодного дня",
/// [Weekdays.everyDay] (== 127) — щодня.
abstract final class Weekdays {
  static const int everyDay = 127;

  /// Короткі підписи Пн…Нд за індексом `weekday - 1`.
  static const List<String> shortLabels = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Нд',
  ];

  static int _bit(int weekday) => 1 << (weekday - 1);

  static bool contains(int mask, int weekday) => mask & _bit(weekday) != 0;

  static int toggle(int mask, int weekday) => mask ^ _bit(weekday);

  /// Список днів ([DateTime.weekday]), увімкнених у масці, у порядку Пн→Нд.
  static List<int> toWeekdays(int mask) => [
        for (var weekday = 1; weekday <= 7; weekday++)
          if (contains(mask, weekday)) weekday,
      ];

  /// Людиночитний опис набору днів для списку нагадувань.
  static String describe(int mask) {
    final days = toWeekdays(mask);
    if (days.isEmpty) return 'Не повторюється';
    if (days.length == 7) return 'Щодня';
    if (days.length == 5 && !contains(mask, DateTime.saturday) && !contains(mask, DateTime.sunday)) {
      return 'По буднях';
    }
    if (days.length == 2 && contains(mask, DateTime.saturday) && contains(mask, DateTime.sunday)) {
      return 'На вихідних';
    }
    return days.map((d) => shortLabels[d - 1]).join(', ');
  }
}
