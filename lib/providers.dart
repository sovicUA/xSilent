import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/reminders_repository.dart';
import 'database/database.dart';
import 'services/notification_service.dart';
import 'services/speech_alarm.dart';
import 'services/tts_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final speechAlarmSchedulerProvider = Provider<SpeechAlarmScheduler>((ref) {
  return const SpeechAlarmScheduler();
});

/// Живе озвучення для прев'ю в редакторі нагадування.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(speechAlarmSchedulerProvider),
  );
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchAll();
});
