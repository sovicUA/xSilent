import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'tts_service.dart';

const String _localeKey = 'app_locale';
const String _voiceKey = 'tts_voice';

/// Регіони, для яких «Авто» дає українську; решта — англійська.
const Set<String> _ukRegions = {'UA', 'RU', 'BY'};

/// Заповнюється в `main()` через `overrideWithValue`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider не ініціалізовано'),
);

/// Обрана користувачем мова: `null` — авто (за регіоном пристрою).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(_localeKey);
    return switch (code) {
      'uk' => const Locale('uk'),
      'en' => const Locale('en'),
      _ => null,
    };
  }

  Future<void> set(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
    state = locale;
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Обраний користувачем голос озвучення: `null` — голос рушія за замовчуванням.
class TtsVoiceController extends Notifier<TtsVoice?> {
  @override
  TtsVoice? build() =>
      TtsVoice.fromStorage(ref.read(sharedPreferencesProvider).getString(_voiceKey));

  Future<void> set(TtsVoice? voice) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (voice == null) {
      await prefs.remove(_voiceKey);
    } else {
      await prefs.setString(_voiceKey, voice.storageKey);
    }
    state = voice;
  }
}

final ttsVoiceControllerProvider =
    NotifierProvider<TtsVoiceController, TtsVoice?>(TtsVoiceController.new);

/// Локальні українські голоси рушія TTS (для екрана налаштувань).
final ukTtsVoicesProvider = FutureProvider<List<TtsVoice>>(
  (ref) => availableUkVoices(FlutterTts()),
);

/// Локалі пристрою. Початкове значення береться з `PlatformDispatcher`, але на
/// старті воно буває неточним (Android віддає `ro.product.locale` ще до того, як
/// рушій приєднає конфіг Activity), тож слухаємо `didChangeLocales` і оновлюємо
/// стан, коли система повідомляє фактичний список.
class DeviceLocales extends Notifier<List<Locale>> with WidgetsBindingObserver {
  @override
  List<Locale> build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return binding.platformDispatcher.locales;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    state = locales ?? const <Locale>[];
  }
}

final deviceLocalesProvider =
    NotifierProvider<DeviceLocales, List<Locale>>(DeviceLocales.new);

/// Фактична мова UI — єдине джерело правди і для `MaterialApp`, і для сервісів
/// та фонового коду: явний вибір користувача або автовибір за регіоном.
final effectiveLocaleProvider = Provider<Locale>((ref) {
  final chosen = ref.watch(localeControllerProvider);
  if (chosen != null) return chosen;
  return regionLocale(ref.watch(deviceLocalesProvider));
});

/// Синхронний доступ до рядків з-поза `BuildContext`.
final l10nProvider = Provider<L10n>(
  (ref) => lookupL10n(ref.watch(effectiveLocaleProvider)),
);

/// Автовибір за регіоном пристрою: {UA, RU, BY} → uk, інакше → en.
Locale regionLocale(Iterable<Locale>? deviceLocales) {
  final country = deviceLocales != null && deviceLocales.isNotEmpty
      ? deviceLocales.first.countryCode
      : null;
  return _ukRegions.contains(country?.toUpperCase())
      ? const Locale('uk')
      : const Locale('en');
}
