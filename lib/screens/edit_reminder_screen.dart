import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../providers.dart';

class EditReminderScreen extends ConsumerStatefulWidget {
  const EditReminderScreen({super.key, this.reminder});

  final Reminder? reminder;

  bool get isNew => reminder == null;

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late TimeOfDay _time;
  late int _weekdayMask;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(
      text: reminder?.title ?? 'Хвилина мовчання',
    );
    _bodyController = TextEditingController(text: reminder?.body ?? '');
    _time = reminder == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    _weekdayMask = reminder?.weekdayMask ?? Weekdays.everyDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _weekdayMask != 0;

  Future<void> _save() async {
    final repository = ref.read(remindersRepositoryProvider);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final reminder = widget.reminder;

    if (reminder == null) {
      await repository.create(
        title: title,
        body: body,
        hour: _time.hour,
        minute: _time.minute,
        weekdayMask: _weekdayMask,
      );
    } else {
      await repository.update(
        reminder,
        title: title,
        body: body,
        hour: _time.hour,
        minute: _time.minute,
        weekdayMask: _weekdayMask,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Нове нагадування' : 'Редагувати'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Зберегти'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Час'),
              trailing: Text(
                _time.format(context),
                style: theme.textTheme.headlineSmall,
              ),
              onTap: _pickTime,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Назва',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Текст сповіщення',
              helperText: 'Необовʼязково — показується під назвою у шторці',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text('Повторювати', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(Weekdays.shortLabels[weekday - 1]),
                  selected: Weekdays.contains(_weekdayMask, weekday),
                  onSelected: (_) => setState(() {
                    _weekdayMask = Weekdays.toggle(_weekdayMask, weekday);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _weekdayMask = Weekdays.everyDay),
                child: const Text('Щодня'),
              ),
              TextButton(
                onPressed: () => setState(() => _weekdayMask = 0x1F),
                child: const Text('По буднях'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
