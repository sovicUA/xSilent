import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

const String _preferredLanguage = 'uk-UA';

/// Спільне налаштування рушія TTS — використовується і кнопкою «Прослухати»
/// в редакторі, і фоновим ізолятом аларму.
///
/// Топ-рівнева функція навмисно: її має викликати `@pragma('vm:entry-point')`
/// callback у власному ізоляті.
Future<void> configureTts(FlutterTts tts) async {
  await tts.awaitSpeakCompletion(true);

  var language = _preferredLanguage;
  final available = await tts.isLanguageAvailable(_preferredLanguage);
  if (available != true) {
    // Українська озвучка не встановлена в рушії — говоримо дефолтною мовою,
    // це краще за тишу. Підказку про встановлення додамо в налаштуваннях.
    language = 'uk';
  }
  try {
    await tts.setLanguage(language);
  } catch (_) {
    // Ігноруємо: рушій візьме мову за замовчуванням.
  }

  await tts.setSpeechRate(0.5);
  await tts.setPitch(1.0);
  await tts.setVolume(1.0);

  if (Platform.isAndroid) {
    // Клас аудіо «голос навігатора» (USAGE_ASSISTANCE_NAVIGATION_GUIDANCE):
    // на відміну від звичайного медіа, ОС дозволяє його з фону та коли
    // пристрій заблокований (як голос Google Maps). Потрібно, щоб озвучення
    // з фонового alarm-ізоляту не відкладалося до розблокування (Motorola).
    await tts.setAudioAttributesForNavigation();
  }

  if (Platform.isIOS) {
    await tts.setSharedInstance(true);
  }
}

/// Живе озвучення для прев'ю в UI. Тримає один екземпляр [FlutterTts].
class TtsService {
  FlutterTts? _tts;
  bool _configured = false;

  Future<FlutterTts> _ready() async {
    final tts = _tts ??= FlutterTts();
    if (!_configured) {
      await configureTts(tts);
      _configured = true;
    }
    return tts;
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final tts = await _ready();
    await tts.stop();
    await tts.speak(trimmed, focus: true);
  }

  Future<void> stop() async {
    await _tts?.stop();
  }

  void dispose() {
    _tts?.stop();
    _tts = null;
    _configured = false;
  }
}
