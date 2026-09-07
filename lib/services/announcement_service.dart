import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/wav.dart';
import 'sound_store.dart';
import 'tts_service.dart';

class AnnouncementException implements Exception {
  AnnouncementException(this.message);
  final String message;
  @override
  String toString() => 'AnnouncementException: $message';
}

class AnnouncementResult {
  AnnouncementResult({
    required this.contentUri,
    required this.channelId,
    required this.soundName,
    required this.duration,
  });

  final String contentUri;
  final String channelId;
  final String soundName;
  final Duration duration;
}

/// Скільки цокання метронома додати в кінець доріжки озвучення.
enum _TickFill {
  /// Без цокання.
  none,

  /// Кілька тактів — для кнопки «Прослухати».
  sample,

  /// Заповнити доріжку цоканням до [AnnouncementService.silenceLength] —
  /// реальний звук сповіщення хвилини мовчання.
  full,
}

/// Який гонг ставити перед голосом.
enum Gong {
  /// Основний — для вбудованого нагадування «Хвилина мовчання».
  main('assets/audio/main_gong.wav', 'm'),

  /// Додатковий — для нагадувань, доданих користувачем.
  additional('assets/audio/additional_gong.wav', 'a');

  const Gong(this.asset, this.key);
  final String asset;
  final String key;
}

/// Генерує аудіофайл озвучення нагадування («гонг + пауза + мовлення»)
/// і кладе його у спільне сховище як звук каналу сповіщення.
class AnnouncementService {
  AnnouncementService([SoundStore? soundStore, FlutterTts? tts])
      : _sound = soundStore ?? const SoundStore(),
        _tts = tts ?? FlutterTts();

  final SoundStore _sound;
  final FlutterTts _tts;

  bool _ttsReady = false;
  final Map<Gong, WavData> _gongs = {};
  Future<void>? _running; // серіалізація синтезу

  static const Duration _gap = Duration(milliseconds: 400);
  static const double _gongGain = 0.85;
  static const Duration maxLength = Duration(seconds: 30);

  /// Тривалість хвилини мовчання — доріжка озвучення з метрономом
  /// заповнюється цоканням до цього значення.
  static const Duration silenceLength = Duration(minutes: 1);

  /// Кілька тактів метронома для прев'ю.
  static const Duration _sampleTicking = Duration(seconds: 4);

  /// Мінімум цокання навіть за довгого вступу.
  static const Duration _minTicking = Duration(seconds: 5);

  /// Гучність кліку метронома (грає цілу хвилину — тихо).
  static const double _tickGain = 0.20;

  /// Версія формату каналу озвучення. Входить у хеш, тож її зміна дає новий
  /// id каналу — потрібно, коли треба, щоб система перестворила канал
  /// (його аудіоатрибути незмінні після створення). `2` — перехід звуку на
  /// потік будильника ([AudioAttributesUsage.alarm]).
  static const String _channelFormatVersion = '2';

  /// Детермінований хеш (FNV-1a 32-біт). `String.hashCode` у Dart
  /// рандомізується на кожен запуск ізоляту — тут це неприпустимо.
  String _hash(String text, double volume, Gong gong, bool ticking) {
    var h = 0x811c9dc5;
    final key = '$text|${(volume * 100).round()}|${gong.key}'
        '|${ticking ? 't' : ''}|$_channelFormatVersion';
    for (final code in key.codeUnits) {
      h = (h ^ code) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  String channelId(
    int reminderId,
    String text,
    double volume,
    Gong gong, {
    bool ticking = false,
  }) =>
      'spoken_r${reminderId}_${_hash(text, volume, gong, ticking)}';

  String soundName(
    int reminderId,
    String text,
    double volume,
    Gong gong, {
    bool ticking = false,
  }) =>
      'xsilent_r${reminderId}_${_hash(text, volume, gong, ticking)}.wav';

  String soundPrefix(int reminderId) => 'xsilent_r${reminderId}_';
  String channelPrefix(int reminderId) => 'spoken_r${reminderId}_';

  Future<WavData> _gong(Gong gong) async {
    return _gongs[gong] ??= readWav(
      (await rootBundle.load(gong.asset)).buffer.asUint8List(),
    );
  }

  Future<({String localPath, Duration duration})> _render(
    int reminderId,
    String text,
    double volume,
    Gong gong,
    _TickFill tick,
  ) async {
    while (_running != null) {
      await _running;
    }
    final completer = Completer<void>();
    _running = completer.future;
    try {
      return await _renderLocked(reminderId, text, volume, gong, tick);
    } finally {
      _running = null;
      completer.complete();
    }
  }

  /// Синтезує мовлення в WAV-моно й повертає його. `null` — якщо [text] порожній.
  Future<WavData?> _speech(int reminderId, String text) async {
    if (text.trim().isEmpty) return null;

    if (!_ttsReady) {
      await configureTts(_tts);
      await _tts.awaitSynthCompletion(true);
      _ttsReady = true;
    }

    final tmp = await getTemporaryDirectory();
    final speechPath = '${tmp.path}/tts_r$reminderId.wav';
    final speechFile = File(speechPath);
    if (speechFile.existsSync()) speechFile.deleteSync();

    try {
      await _tts
          .synthesizeToFile(text, speechPath, true)
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw AnnouncementException('Синтез мовлення перевищив час очікування');
    } catch (e) {
      throw AnnouncementException('Не вдалося синтезувати мовлення: $e');
    }

    if (!speechFile.existsSync() || speechFile.lengthSync() < 128) {
      throw AnnouncementException('Файл мовлення не створено (немає TTS-рушія?)');
    }

    final WavData speech;
    try {
      speech = readWav(await speechFile.readAsBytes());
    } on FormatException catch (e) {
      throw AnnouncementException('TTS повернув некоректний WAV: ${e.message}');
    }
    if (speech.channels != 1) {
      throw AnnouncementException(
        'TTS повернув не моно (${speech.channels} каналів)',
      );
    }
    return speech;
  }

  Future<({String localPath, Duration duration})> _renderLocked(
    int reminderId,
    String text,
    double volume,
    Gong gong,
    _TickFill tick,
  ) async {
    final speech = await _speech(reminderId, text);
    final tmp = await getTemporaryDirectory();
    // Частота дискретизації: від TTS, інакше — від гонга.
    final rate = speech?.sampleRate ?? (await _gong(gong)).sampleRate;

    final gongWav = await _gong(gong);
    var gongPcm = gongWav.pcm;
    if (gongWav.sampleRate != rate) {
      gongPcm = resamplePcmS16Mono(gongPcm, gongWav.sampleRate, rate);
    }

    final combined = BytesBuilder()
      ..add(scalePcmS16(gongPcm, _gongGain * volume));
    if (speech != null) {
      // Рушії TTS часто віддають файл на 0 dBFS із кліпом — стишуємо до запасу,
      // щоб мовлення не хрипіло при відтворенні.
      combined
        ..add(silencePcm(rate, _gap))
        ..add(scalePcmS16(speech.pcm, volume * peakScale(speech.pcm)));
    }

    if (tick != _TickFill.none) {
      final introMs = combined.length / (rate * 2) * 1000;
      final ticking = switch (tick) {
        _TickFill.sample => _sampleTicking,
        _TickFill.full => Duration(
            milliseconds: math.max(
              _minTicking.inMilliseconds,
              (silenceLength.inMilliseconds - introMs).round(),
            ),
          ),
        _TickFill.none => Duration.zero,
      };
      combined.add(metronomeTrackPcm(rate, ticking, gain: _tickGain * volume));
    }

    final pcm = combined.toBytes();
    final wav = buildWav(sampleRate: rate, pcmS16le: pcm);
    final outPath = '${tmp.path}/announcement_r$reminderId.wav';
    await File(outPath).writeAsBytes(wav, flush: true);

    final seconds = pcm.lengthInBytes / (rate * 2);
    return (
      localPath: outPath,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    );
  }

  /// Генерація для збереження: файл потрапляє у MediaStore, повертається URI.
  Future<AnnouncementResult> build({
    required int reminderId,
    required String text,
    required double volume,
    required Gong gong,
    bool ticking = false,
  }) async {
    final rendered = await _render(
      reminderId,
      text,
      volume,
      gong,
      ticking ? _TickFill.full : _TickFill.none,
    );
    final name = soundName(reminderId, text, volume, gong, ticking: ticking);
    final uri = await _sound.put(name, rendered.localPath);
    return AnnouncementResult(
      contentUri: uri,
      channelId: channelId(reminderId, text, volume, gong, ticking: ticking),
      soundName: name,
      duration: rendered.duration,
    );
  }

  /// Генерація для прев'ю: без MediaStore, локальний файл для програвання.
  Future<({String localPath, Duration duration})> preview({
    required String text,
    required double volume,
    required Gong gong,
    bool ticking = false,
  }) {
    return _render(
      0,
      text,
      volume,
      gong,
      ticking ? _TickFill.sample : _TickFill.none,
    );
  }
}
