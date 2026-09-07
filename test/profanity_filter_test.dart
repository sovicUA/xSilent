import 'package:flutter_test/flutter_test.dart';
import 'package:xsilent/services/profanity_filter.dart';

void main() {
  group('ProfanityFilter', () {
    test('пропускає нормальний текст оголошень', () {
      const clean = [
        'Оголошується загальнонаціональна хвилина мовчання.',
        'Вшануймо пам’ять усіх, хто віддав життя за Україну.',
        'Схиляємо голови у скорботі.',
        'Attention. The nationwide moment of silence begins now.',
        'Команда збирається о девʼятій. Мандарини на столі.',
        'Дубові гілки й сухі суки згорять у вогні', // «суки» = гілки
      ];
      for (final t in clean) {
        expect(ProfanityFilter.containsProfanity(t), isFalse, reason: t);
      }
    });

    test('ловить пряму лайку та словоформи', () {
      const dirty = [
        'йди на хуй',
        'от бляха, тобто блядь',
        'повний пиздець',
        'заєбало все',
        'ти мудак',
        'this is fucking bad',
        'what a bitch',
      ];
      for (final t in dirty) {
        expect(ProfanityFilter.containsProfanity(t), isTrue, reason: t);
      }
    });

    test('ловить обфускацію: двійники, роздільники, повтори', () {
      expect(ProfanityFilter.containsProfanity('х у й'), isTrue);
      expect(ProfanityFilter.containsProfanity('xyй тобі'), isTrue);
      expect(ProfanityFilter.containsProfanity('бл*я*д*ь'), isTrue);
      expect(ProfanityFilter.containsProfanity('хуууйня'), isTrue);
      expect(ProfanityFilter.containsProfanity('6лядь'), isTrue);
    });

    test('порожній рядок — чисто', () {
      expect(ProfanityFilter.containsProfanity(''), isFalse);
      expect(ProfanityFilter.containsProfanity('   '), isFalse);
    });
  });
}
