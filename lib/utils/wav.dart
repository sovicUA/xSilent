import 'dart:math' as math;
import 'dart:typed_data';

/// Мінімальні утиліти для роботи з PCM/WAV (16-біт signed little-endian).
///
/// Використовуються для склейки «гонг + мовлення» в один файл озвучення.

class WavData {
  const WavData({
    required this.sampleRate,
    required this.channels,
    required this.pcm,
  });

  final int sampleRate;
  final int channels;
  final Uint8List pcm;

  double get durationSeconds =>
      pcm.lengthInBytes / (sampleRate * channels * 2);
}

/// Обгортає сирий PCM (s16le) у WAV-контейнер.
Uint8List buildWav({
  required int sampleRate,
  required Uint8List pcmS16le,
  int channels = 1,
}) {
  final byteRate = sampleRate * channels * 2;
  final blockAlign = channels * 2;
  final dataLen = pcmS16le.lengthInBytes;
  final out = BytesBuilder();

  void str(String s) => out.add(s.codeUnits);
  void u32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    out.add(b.buffer.asUint8List());
  }

  void u16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    out.add(b.buffer.asUint8List());
  }

  str('RIFF');
  u32(36 + dataLen);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1); // PCM
  u16(channels);
  u32(sampleRate);
  u32(byteRate);
  u16(blockAlign);
  u16(16); // bits per sample
  str('data');
  u32(dataLen);
  out.add(pcmS16le);
  return out.toBytes();
}

/// Розбирає WAV, повертає параметри та сирий PCM (`data`).
WavData readWav(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  if (bytes.lengthInBytes < 12 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
    throw const FormatException('Не WAV-файл');
  }
  var offset = 12;
  int sampleRate = 0;
  int channels = 1;
  int audioFormat = 1;
  int bitsPerSample = 16;
  while (offset + 8 <= bytes.lengthInBytes) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = bd.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      audioFormat = bd.getUint16(body, Endian.little);
      channels = bd.getUint16(body + 2, Endian.little);
      sampleRate = bd.getUint32(body + 4, Endian.little);
      bitsPerSample = bd.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      // Далі весь конвеєр (`Int16List.sublistView`, ресемплінг, склейка)
      // припускає PCM signed-16 little-endian. Формати від TTS-рушіїв
      // трапляються різні — відсікаємо тут із чітким повідомленням.
      if (audioFormat != 1) {
        throw FormatException('WAV не PCM (audioFormat=$audioFormat)');
      }
      if (bitsPerSample != 16) {
        throw FormatException('WAV не 16-біт (bitsPerSample=$bitsPerSample)');
      }
      if (sampleRate <= 0) {
        throw const FormatException('У WAV немає коректного fmt-чанку');
      }
      final end = math.min(body + size, bytes.lengthInBytes);
      return WavData(
        sampleRate: sampleRate,
        channels: channels,
        pcm: Uint8List.sublistView(bytes, body, end),
      );
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('У WAV немає data-чанку');
}

/// Тиша заданої тривалості (s16le).
Uint8List silencePcm(int sampleRate, Duration duration, {int channels = 1}) {
  final samples = (sampleRate * duration.inMicroseconds / 1e6).round();
  return Uint8List(samples * channels * 2);
}

/// Лінійний ресемплінг s16le-моно. Для короткого гонга якості достатньо.
Uint8List resamplePcmS16Mono(Uint8List pcm, int fromRate, int toRate) {
  if (fromRate == toRate) return pcm;
  final src = Int16List.sublistView(pcm);
  final outLen = (src.length * toRate / fromRate).floor();
  final out = Int16List(outLen);
  for (var i = 0; i < outLen; i++) {
    final srcPos = i * fromRate / toRate;
    final i0 = srcPos.floor();
    final i1 = math.min(i0 + 1, src.length - 1);
    final t = srcPos - i0;
    out[i] = (src[i0] * (1 - t) + src[i1] * t).round().clamp(-32768, 32767);
  }
  return out.buffer.asUint8List();
}

/// Множення амплітуди з жорстким кліпом.
Uint8List scalePcmS16(Uint8List pcm, double gain) {
  if (gain == 1.0) return pcm;
  final src = Int16List.sublistView(pcm);
  final out = Int16List(src.length);
  for (var i = 0; i < src.length; i++) {
    out[i] = (src[i] * gain).round().clamp(-32768, 32767);
  }
  return out.buffer.asUint8List();
}

/// Тривалість WAV у секундах.
double wavDurationSeconds(Uint8List bytes) => readWav(bytes).durationSeconds;

/// Один клік метронома: короткий загасаючий тон (s16le-моно).
Uint8List metronomeTickPcm(int sampleRate, {double gain = 0.35}) {
  const durMs = 26;
  const freq = 2000.0;
  final n = (sampleRate * durMs / 1000).round();
  final out = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = math.exp(-t * 240); // швидке загасання — «клац»
    final s = math.sin(2 * math.pi * freq * t) * env * gain;
    out[i] = (s * 32767).round().clamp(-32768, 32767);
  }
  return out.buffer.asUint8List();
}

/// Доріжка метронома тривалістю [total]: клік на початку кожної секунди,
/// решта секунди — тиша (s16le-моно).
Uint8List metronomeTrackPcm(int sampleRate, Duration total, {double gain = 0.35}) {
  final totalSamples = (sampleRate * total.inMicroseconds / 1e6).round();
  final out = Int16List(math.max(0, totalSamples));
  final tick = Int16List.sublistView(metronomeTickPcm(sampleRate, gain: gain));
  for (var start = 0; start < out.length; start += sampleRate) {
    for (var j = 0; j < tick.length && start + j < out.length; j++) {
      out[start + j] = tick[j];
    }
  }
  return out.buffer.asUint8List();
}
