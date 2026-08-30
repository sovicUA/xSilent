import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();
  await container.read(remindersRepositoryProvider).seedDefaultIfEmpty();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const XSilentApp(),
    ),
  );
}
