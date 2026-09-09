import 'package:flutter_test/flutter_test.dart';
import 'package:xsilent/services/tts_service.dart';

void main() {
  group('TtsVoice storage', () {
    test('round-trip', () {
      const v = TtsVoice(name: 'uk-ua-x-hfd-local', locale: 'uk-UA');
      final back = TtsVoice.fromStorage(v.storageKey);
      expect(back, v);
    });

    test('null / некоректний рядок', () {
      expect(TtsVoice.fromStorage(null), isNull);
      expect(TtsVoice.fromStorage('без-пробілу'), isNull);
    });
  });

  group('parseUkVoices', () {
    test('лишає укр. голоси (з мережевими), без дублів, сортовано', () {
      final raw = [
        {'name': 'uk-ua-x-hfd-network', 'locale': 'uk-UA', 'network_required': '1'},
        {'name': 'uk-ua-x-hfd-local', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'uk-UA-language', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'uk-ua-x-hfd-local', 'locale': 'uk-UA', 'network_required': '0'}, // дубль
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US', 'network_required': '0'},
        {'name': '', 'locale': 'uk-UA', 'network_required': '0'},
      ];
      final voices = parseUkVoices(raw);
      // локальні перед мережевими
      expect(voices.map((v) => v.name).toList(),
          ['uk-UA-language', 'uk-ua-x-hfd-local', 'uk-ua-x-hfd-network']);
      expect(voices.last.network, isTrue);
      expect(voices.first.network, isFalse);
    });

    test('сортування: жіночі → чоловічі → інші, потім за іменем', () {
      final raw = [
        {'name': 'zzz-unknown', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'Anatol', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'Natalia', 'locale': 'uk-UA', 'network_required': '0'},
      ];
      expect(parseUkVoices(raw).map((v) => v.name).toList(),
          ['Natalia', 'Anatol', 'zzz-unknown']);
    });

    test('не список → порожньо', () {
      expect(parseUkVoices(null), isEmpty);
      expect(parseUkVoices('щось'), isEmpty);
    });
  });

  group('guessVoiceGender', () {
    test('явні слова та features', () {
      expect(guessVoiceGender('some-female-voice', ''), TtsGender.female);
      expect(guessVoiceGender('voice-1', 'gender=male'), TtsGender.male);
    });

    test('українські імена (RHVoice)', () {
      expect(guessVoiceGender('Natalia', ''), TtsGender.female);
      expect(guessVoiceGender('Anatol', ''), TtsGender.male);
    });

    test('Google uk — набір hfd жіночий', () {
      expect(guessVoiceGender('uk-ua-x-hfd-local', ''), TtsGender.female);
      expect(guessVoiceGender('uk-UA-language', ''), TtsGender.female);
    });

    test('невідомий', () {
      expect(guessVoiceGender('xx-yy-x-abc-local', ''), TtsGender.unknown);
    });
  });
}
