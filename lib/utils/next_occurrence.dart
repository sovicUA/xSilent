/// Наступний момент часу, що **строго після** [from] (за замовчуванням — тепер),
/// збігається за днем тижня ([DateTime.weekday]: 1 = понеділок … 7 = неділя)
/// та за годиною/хвилиною.
DateTime nextWeekdayTime(
  int hour,
  int minute,
  int weekday, {
  DateTime? from,
}) {
  final base = from ?? DateTime.now();
  var scheduled = DateTime(base.year, base.month, base.day, hour, minute);
  while (scheduled.weekday != weekday || !scheduled.isAfter(base)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
