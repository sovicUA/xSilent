import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';

import 'package:xsilent/l10n/app_localizations.dart';
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
      final uk = lookupL10n(const Locale('uk'));
      expect(Weekdays.describe(Weekdays.everyDay, uk), 'Щодня');
      expect(Weekdays.describe(0x1F, uk), 'По буднях');
      expect(Weekdays.describe(0, uk), 'Не повторюється');
      expect(Weekdays.describe(0x60, uk), 'На вихідних');
    });

    test('describe англійською', () {
      final en = lookupL10n(const Locale('en'));
      expect(Weekdays.describe(Weekdays.everyDay, en), 'Every day');
      expect(Weekdays.describe(0x1F, en), 'Weekdays');
    });
  });
}
