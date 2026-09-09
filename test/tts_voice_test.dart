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
    test('лишає лише укр. локальні, без дублів, сортовано', () {
      final raw = [
        {'name': 'uk-ua-x-hfd-network', 'locale': 'uk-UA', 'network_required': '1'},
        {'name': 'uk-ua-x-hfd-local', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'uk-UA-language', 'locale': 'uk-UA', 'network_required': '0'},
        {'name': 'uk-ua-x-hfd-local', 'locale': 'uk-UA', 'network_required': '0'}, // дубль
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US', 'network_required': '0'},
        {'name': '', 'locale': 'uk-UA', 'network_required': '0'},
      ];
      final voices = parseUkVoices(raw);
      expect(voices.map((v) => v.name).toList(),
          ['uk-UA-language', 'uk-ua-x-hfd-local']);
    });

    test('не список → порожньо', () {
      expect(parseUkVoices(null), isEmpty);
      expect(parseUkVoices('щось'), isEmpty);
    });
  });
}
