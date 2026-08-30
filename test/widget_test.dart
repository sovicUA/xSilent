import 'package:flutter_test/flutter_test.dart';

import 'package:xsilent/models/weekdays.dart';

void main() {
  group('Weekdays', () {
    test('everyDay містить усі дні', () {
      expect(Weekdays.toWeekdays(Weekdays.everyDay), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('toggle вмикає та вимикає день', () {
      var mask = 0;
      mask = Weekdays.toggle(mask, DateTime.monday);
      expect(Weekdays.contains(mask, DateTime.monday), isTrue);
      mask = Weekdays.toggle(mask, DateTime.monday);
      expect(Weekdays.contains(mask, DateTime.monday), isFalse);
    });

    test('describe розпізнає типові набори', () {
      expect(Weekdays.describe(Weekdays.everyDay), 'Щодня');
      expect(Weekdays.describe(0x1F), 'По буднях');
      expect(Weekdays.describe(0), 'Не повторюється');
    });
  });
}
