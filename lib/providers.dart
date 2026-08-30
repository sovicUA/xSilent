import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/reminders_repository.dart';
import 'database/database.dart';
import 'services/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchAll();
});
