import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../providers.dart';
import 'edit_reminder_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  Future<void> _openEditor([Reminder? reminder]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(reminder: reminder),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Хвилина мовчання'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Налаштування',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Помилка: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) => _ReminderTile(
              reminder: items[index],
              onTap: () => _openEditor(items[index]),
            ),
            separatorBuilder: (_, _) => const Divider(height: 1),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Нагадування'),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder, required this.onTap});

  final Reminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(remindersRepositoryProvider);
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: reminder.isBuiltIn
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Видалити нагадування?'),
                content: Text('«${reminder.title}» буде видалено.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Скасувати'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Видалити'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => repository.delete(reminder),
      child: ListTile(
        onTap: onTap,
        title: Text(
          time.format(context),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: reminder.enabled ? null : theme.disabledColor,
          ),
        ),
        subtitle: Text(
          '${reminder.title} · ${Weekdays.describe(reminder.weekdayMask)}',
        ),
        trailing: Switch(
          value: reminder.enabled,
          onChanged: (value) => repository.setEnabled(reminder, value),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 64),
            const SizedBox(height: 16),
            Text(
              'Немає нагадувань',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Додайте нагадування кнопкою внизу.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
