import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../providers.dart';
import '../widgets/candle_flame.dart';
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
          if (items.isEmpty) return const _EmptyState();

          // Вбудоване «Хвилина мовчання» завжди перше; далі — власні, за часом
          // (стрім уже відсортований по годині/хвилині).
          final builtIn = items.where((r) => r.isBuiltIn).toList();
          final custom = items.where((r) => !r.isBuiltIn).toList();

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            children: [
              for (final reminder in builtIn)
                _BuiltInTile(
                  reminder: reminder,
                  onTap: () => _openEditor(reminder),
                ),
              if (custom.isNotEmpty)
                const _SectionSeparator(label: 'Нагадування'),
              for (var i = 0; i < custom.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                _ReminderTile(
                  reminder: custom[i],
                  onTap: () => _openEditor(custom[i]),
                ),
              ],
            ],
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

/// Тонка лінія з підписом розділу посередині: `──── Нагадування ────`.
class _SectionSeparator extends StatelessWidget {
  const _SectionSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = Container(height: 1, color: theme.colorScheme.outlineVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Expanded(child: line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: line),
        ],
      ),
    );
  }
}

/// Акцентована плитка вбудованого нагадування «Хвилина мовчання».
class _BuiltInTile extends ConsumerWidget {
  const _BuiltInTile({required this.reminder, required this.onTap});

  final Reminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(remindersRepositoryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final on = cs.onPrimaryContainer;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 26,
          height: 30,
          child: CandleFlame(color: on),
        ),
        title: Text(
          time.format(context),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: reminder.enabled ? on : on.withValues(alpha: 0.4),
          ),
        ),
        subtitle: Text(
          '${reminder.title} · ${Weekdays.describe(reminder.weekdayMask)}',
          style: TextStyle(color: on.withValues(alpha: 0.8)),
        ),
        trailing: Switch(
          value: reminder.enabled,
          onChanged: (value) => repository.setEnabled(reminder, value),
        ),
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
      direction: DismissDirection.endToStart,
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
