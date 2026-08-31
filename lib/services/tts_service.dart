import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

const String _preferredLanguage = 'uk-UA';

/// Спільне налаштування рушія TTS перед синтезом озвучення.
Future<void> configureTts(FlutterTts tts) async {
  var language = _preferredLanguage;
  final available = await tts.isLanguageAvailable(_preferredLanguage);
  if (available != true) {
    // Українська озвучка не встановлена в рушії — говоримо дефолтною мовою,
    // це краще за тишу.
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

  if (Platform.isIOS) {
    await tts.setSharedInstance(true);
  }
}
