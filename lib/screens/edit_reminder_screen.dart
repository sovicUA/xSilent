import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/weekdays.dart';
import '../providers.dart';
import '../services/announcement_service.dart';

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
  final AudioPlayer _player = AudioPlayer();

  late TimeOfDay _time;
  late int _weekdayMask;
  late bool _speakAloud;
  late bool _speakAloudTouched;
  late double _volume;

  bool _previewBusy = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(
      text: reminder?.title ?? 'Сповіщення',
    );
    _bodyController = TextEditingController(text: reminder?.body ?? '');
    _time = reminder == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    _weekdayMask = reminder?.weekdayMask ?? Weekdays.everyDay;
    _speakAloud = reminder?.speakAloud ?? true;
    _speakAloudTouched = reminder != null;
    _volume = reminder?.announcementVolume ?? 1.0;
  }

  bool get _hasBody => _bodyController.text.trim().isNotEmpty;
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
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _preview() async {
    if (_previewBusy || !_hasBody) return;
    setState(() => _previewBusy = true);
    try {
      final gong = (widget.reminder?.isBuiltIn ?? false)
          ? Gong.main
          : Gong.additional;
      final result = await ref.read(announcementServiceProvider).preview(
            text: _bodyController.text.trim(),
            volume: _volume,
            gong: gong,
          );
      if (!mounted) return;
      if (result.duration > AnnouncementService.maxLength) {
        _showSnack(
          'Озвучення триває ${result.duration.inSeconds} с. У сповіщенні воно '
          'буде обрізане до ~30 с — скоротіть текст.',
        );
      }
      await _player.stop();
      await _player.play(DeviceFileSource(result.localPath));
    } on AnnouncementException catch (e) {
      if (mounted) _showSnack('Не вдалося озвучити: ${e.message}');
    } finally {
      if (mounted) setState(() => _previewBusy = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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
        announcementVolume: _volume,
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
        announcementVolume: _volume,
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
                icon: _previewBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_up_outlined),
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
                  ? 'Програти «гонг + текст» при спрацюванні'
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
          if (_speakAloudEffective) ...[
            Row(
              children: [
                const Icon(Icons.volume_down_outlined, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    label: '${(_volume * 100).round()}%',
                    divisions: 20,
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ),
                const Icon(Icons.volume_up_outlined, size: 20),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Гучність озвучення: ${(_volume * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
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
