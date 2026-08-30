import 'dart:async';

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

  /// Бажання користувача озвучувати. Діє лише коли є опис ([_hasBody]).
  late bool _speakAloud;

  /// Чи користувач вручну перемикав прапорець — тоді не перевизначаємо його
  /// при введенні опису.
  late bool _speakAloudTouched;

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
    _speakAloud = reminder?.speakAloud ?? true;
    _speakAloudTouched = reminder != null;
  }

  bool get _hasBody => _bodyController.text.trim().isNotEmpty;

  /// Фактичний стан прапорця з урахуванням наявності опису.
  bool get _speakAloudEffective => _hasBody && _speakAloud;

  void _onBodyChanged(String _) {
    setState(() {
      if (!_speakAloudTouched) _speakAloud = _hasBody;
    });
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

  Future<void> _preview() async {
    await ref.read(ttsServiceProvider).speak(_bodyController.text.trim());
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
        speakAloud: _speakAloudEffective,
      );
    } else {
      await repository.update(
        reminder,
        title: title,
        body: body,
        hour: _time.hour,
        minute: _time.minute,
        weekdayMask: _weekdayMask,
        speakAloud: _speakAloudEffective,
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
            decoration: InputDecoration(
              labelText: 'Текст сповіщення',
              helperText: 'Необовʼязково — показується під назвою у шторці',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: 'Прослухати',
                onPressed: _hasBody ? () => unawaited(_preview()) : null,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            onChanged: _onBodyChanged,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Озвучити сповіщення'),
            subtitle: Text(
              _hasBody
                  ? 'Проговорити текст уголос при спрацюванні (TTS)'
                  : 'Додайте текст сповіщення, щоб увімкнути',
            ),
            value: _speakAloudEffective,
            onChanged: _hasBody
                ? (value) => setState(() {
                      _speakAloud = value;
                      _speakAloudTouched = true;
                    })
                : null,
          ),
          const SizedBox(height: 16),
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
