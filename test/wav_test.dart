import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xsilent/utils/wav.dart';

void main() {
  group('WAV utils', () {
    test('buildWav → readWav round-trip', () {
      final pcm = Uint8List.fromList(List.generate(2000, (i) => i % 256));
      final wav = buildWav(sampleRate: 24000, pcmS16le: pcm);
      final parsed = readWav(wav);
      expect(parsed.sampleRate, 24000);
      expect(parsed.channels, 1);
      expect(parsed.pcm.length, pcm.length);
      expect(parsed.pcm, pcm);
    });

    test('durationSeconds', () {
      // 24000 Гц моно 16-біт → 1 с = 48000 байт
      final wav = buildWav(
        sampleRate: 24000,
        pcmS16le: Uint8List(48000),
      );
      expect(wavDurationSeconds(wav), closeTo(1.0, 0.001));
    });

    test('silencePcm довжина', () {
      final s = silencePcm(24000, const Duration(milliseconds: 500));
      expect(s.length, 24000); // 0.5 с × 24000 × 2 байти
      expect(s.every((b) => b == 0), isTrue);
    });

    test('scalePcmS16 множить і кліпить', () {
      final src = Int16List.fromList([1000, -1000, 30000, -30000]);
      final scaled = Int16List.sublistView(
        scalePcmS16(src.buffer.asUint8List(), 2.0),
      );
      expect(scaled[0], 2000);
      expect(scaled[1], -2000);
      expect(scaled[2], 32767); // кліп
      expect(scaled[3], -32768); // кліп
    });

    test('resamplePcmS16Mono змінює довжину пропорційно', () {
      final src = Uint8List(24000 * 2); // 1 с @ 24000
      final up = resamplePcmS16Mono(src, 24000, 48000);
      expect(up.length, closeTo(48000 * 2, 4));
    });

    test('readWav відхиляє не-PCM і не-16-біт', () {
      // Валідний PCM16 як база, далі патчимо поля fmt-чанку.
      final base = buildWav(sampleRate: 24000, pcmS16le: Uint8List(64));
      final fmtBody = 20; // 12 (RIFF/WAVE) + 8 (id+size 'fmt ')

      Uint8List patched(int offset, int value) {
        final copy = Uint8List.fromList(base);
        ByteData.sublistView(copy).setUint16(offset, value, Endian.little);
        return copy;
      }

      // audioFormat = 3 (IEEE float)
      expect(() => readWav(patched(fmtBody, 3)), throwsFormatException);
      // bitsPerSample = 8
      expect(() => readWav(patched(fmtBody + 14, 8)), throwsFormatException);
    });

    test('readWav відхиляє не-WAV', () {
      expect(
        () => readWav(Uint8List.fromList('not a wav file at all'.codeUnits)),
        throwsFormatException,
      );
    });

    test('metronomeTrackPcm — тривалість і по кліку на секунду', () {
      const rate = 24000;
      final track = Int16List.sublistView(
        metronomeTrackPcm(rate, const Duration(seconds: 5)),
      );
      expect(track.length, rate * 5); // 5 с

      int energy(int from, int to) {
        var e = 0;
        for (var i = from; i < to; i++) {
          e += track[i].abs();
        }
        return e;
      }

      for (var s = 0; s < 5; s++) {
        final tickStart = s * rate;
        // Перші ~40 мс секунди — клік (є енергія).
        expect(energy(tickStart, tickStart + rate ~/ 25), greaterThan(0),
            reason: 'клік на секунді $s');
        // Остання половина секунди — тиша.
        expect(energy(tickStart + rate ~/ 2, tickStart + rate), 0,
            reason: 'тиша в кінці секунди $s');
      }
    });

    test('metronomeTrackPcm — нульова тривалість дає порожньо', () {
      expect(metronomeTrackPcm(24000, Duration.zero).length, 0);
    });
  });
}
