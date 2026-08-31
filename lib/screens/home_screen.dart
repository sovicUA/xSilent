import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = L10n.of(context);
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.errorPrefix(error.toString()))),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();

          // Вбудоване завжди перше; далі — власні, за часом (стрім відсортований).
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
                _SectionSeparator(label: l10n.remindersSection),
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
        label: Text(l10n.fabNewReminder),
      ),
    );
  }
}

/// Тонка лінія з підписом розділу посередині.
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
    final l10n = L10n.of(context);
    final repository = ref.read(remindersRepositoryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final on = cs.onPrimaryContainer;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          '${reminder.title} · ${Weekdays.describe(reminder.weekdayMask, l10n)}',
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
    final l10n = L10n.of(context);
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
                title: Text(l10n.deleteTitle),
                content: Text(l10n.deleteBody(reminder.title)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete),
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
          '${reminder.title} · ${Weekdays.describe(reminder.weekdayMask, l10n)}',
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
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 64),
            const SizedBox(height: 16),
            Text(l10n.emptyTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.emptyBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
