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
  });
}
