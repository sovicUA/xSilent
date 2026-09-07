import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
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

  /// Прев'ю має звучати як реальне сповіщення: через потік будильника —
  /// незалежно від гучності медіа/сповіщень і в беззвучному режимі.
  static final AudioContext _alarmAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  late TimeOfDay _time;
  late int _weekdayMask;
  late bool _speakAloud;
  late bool _speakAloudTouched;
  late double _volume;

  bool _previewBusy = false;
  bool _titleDefaultApplied = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _bodyController = TextEditingController(text: reminder?.body ?? '');
    _time = reminder == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    _weekdayMask = reminder?.weekdayMask ?? Weekdays.everyDay;
    _speakAloud = reminder?.speakAloud ?? true;
    _speakAloudTouched = reminder != null;
    _volume = reminder?.announcementVolume ?? 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isNew && !_titleDefaultApplied) {
      _titleController.text = L10n.of(context).newReminderDefaultName;
      _titleDefaultApplied = true;
    }
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
    // Клавіатурний ввід за замовчуванням: на 24-годинному циферблаті `00`
    // стоїть зверху по центру, тож перетягуванням легко промахнутися на 0:00.
    // Кнопка перемикання на циферблат у діалозі лишається.
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _preview() async {
    if (_previewBusy || !_hasBody) return;
    setState(() => _previewBusy = true);
    final l10n = L10n.of(context);
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
        _showSnack(l10n.previewTooLong(result.duration.inSeconds));
      }
      await _player.stop();
      await _player.setAudioContext(_alarmAudioContext);
      await _player.play(DeviceFileSource(result.localPath));
    } on AnnouncementException catch (e) {
      if (mounted) _showSnack(l10n.previewFailed(e.message));
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
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? l10n.editorNewTitle : l10n.editorEditTitle),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.fieldTime),
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
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: l10n.fieldBody,
              helperText: l10n.fieldBodyHelper,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: _previewBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_up_outlined),
                tooltip: l10n.previewTooltip,
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
            title: Text(l10n.speakSwitchTitle),
            subtitle: Text(
              _hasBody ? l10n.speakSwitchOnHint : l10n.speakSwitchOffHint,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.volumeLabel((_volume * 100).round()),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.volumeAlarmHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.repeatTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(Weekdays.shortLabel(l10n, weekday)),
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
                child: Text(l10n.repeatEveryDay),
              ),
              TextButton(
                onPressed: () => setState(() => _weekdayMask = 0x1F),
                child: Text(l10n.repeatWeekdays),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
