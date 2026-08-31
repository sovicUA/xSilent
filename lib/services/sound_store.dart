import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Dart-обгортка над нативним `SoundStore` (MediaStore). Android-only;
/// на інших платформах — no-op / кидає [UnsupportedError] для [put].
class SoundStore {
  const SoundStore();

  static const MethodChannel _channel = MethodChannel('xsilent/sound_store');

  bool get _supported => Platform.isAndroid;

  /// Записує локальний WAV у спільне сховище; повертає `content://` URI,
  /// придатний як звук каналу сповіщення.
  Future<String> put(String displayName, String localFilePath) async {
    if (!_supported) {
      throw UnsupportedError('SoundStore доступний лише на Android');
    }
    final uri = await _channel.invokeMethod<String>('put', {
      'name': displayName,
      'path': localFilePath,
    });
    if (uri == null) throw StateError('SoundStore.put повернув null');
    return uri;
  }

  /// Видаляє всі власні звуки `prefix*`, крім [keepName].
  Future<void> pruneExcept(String prefix, String? keepName) async {
    if (!_supported) return;
    await _channel.invokeMethod<void>('pruneExcept', {
      'prefix': prefix,
      'keep': keepName,
    });
  }

  Future<void> deleteAll(String prefix) async {
    if (!_supported) return;
    await _channel.invokeMethod<void>('deleteAll', {'prefix': prefix});
  }
}
