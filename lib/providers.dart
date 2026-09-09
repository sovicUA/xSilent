import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/reminders_repository.dart';
import 'database/database.dart';
import 'services/announcement_service.dart';
import 'services/app_settings.dart';
import 'services/notification_service.dart';
import 'services/sound_store.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final soundStoreProvider = Provider<SoundStore>((ref) => const SoundStore());

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService(ref.watch(soundStoreProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    l10n: ref.watch(l10nProvider),
    ttsVoice: ref.watch(ttsVoiceControllerProvider),
    announcements: ref.watch(announcementServiceProvider),
    soundStore: ref.watch(soundStoreProvider),
  );
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(l10nProvider),
  );
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchAll();
});
