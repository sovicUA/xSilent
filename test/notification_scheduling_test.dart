import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:xsilent/services/notification_service.dart';

void main() {
  tz_data.initializeTimeZones();
  final kyiv = tz.getLocation('Europe/Kyiv');

  group('nextInstanceOf', () {
    test('той самий день тижня, час пізніше — сьогодні', () {
      final now = tz.TZDateTime(kyiv, 2026, 8, 31, 8, 0); // понеділок
      expect(
        nextInstanceOf(now, 9, 0, DateTime.monday),
        tz.TZDateTime(kyiv, 2026, 8, 31, 9, 0),
      );
    });

    test('той самий день тижня, час уже минув — за тиждень', () {
      final now = tz.TZDateTime(kyiv, 2026, 8, 31, 10, 0); // понеділок
      expect(
        nextInstanceOf(now, 9, 0, DateTime.monday),
        tz.TZDateTime(kyiv, 2026, 9, 7, 9, 0),
      );
    });

    test('інший день тижня — найближчий такий день', () {
      final now = tz.TZDateTime(kyiv, 2026, 8, 31, 10, 0); // понеділок
      final next = nextInstanceOf(now, 9, 0, DateTime.friday);
      expect(next.weekday, DateTime.friday);
      expect(next, tz.TZDateTime(kyiv, 2026, 9, 4, 9, 0));
    });

    test('точно поточний момент не рахується — переходить на тиждень уперед', () {
      final now = tz.TZDateTime(kyiv, 2026, 8, 31, 9, 0); // понеділок 09:00
      expect(
        nextInstanceOf(now, 9, 0, DateTime.monday),
        tz.TZDateTime(kyiv, 2026, 9, 7, 9, 0),
      );
    });
  });
}
