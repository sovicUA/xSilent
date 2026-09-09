import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import '../services/announcement_service.dart';
import '../services/app_settings.dart';
import '../services/tts_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AudioPlayer _player = AudioPlayer();

  /// Прев'ю голосу має звучати як реальне сповіщення — через потік будильника.
  static final AudioContext _alarmAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  String? _samplingKey; // storageKey голосу, що зараз програється (null = дефолт)
  bool _sampleBusy = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _sample(TtsVoice? voice) async {
    if (_sampleBusy) return;
    setState(() {
      _sampleBusy = true;
      _samplingKey = voice?.storageKey;
    });
    final l10n = L10n.of(context);
    try {
      final result = await ref.read(announcementServiceProvider).preview(
            text: l10n.voiceSampleText,
            volume: 1.0,
            gong: Gong.additional,
            voice: voice,
          );
      if (!mounted) return;
      await _player.stop();
      await _player.setAudioContext(_alarmAudioContext);
      await _player.play(DeviceFileSource(result.localPath));
    } on AnnouncementException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.previewFailed(e.message))));
      }
    } finally {
      if (mounted) setState(() => _sampleBusy = false);
    }
  }

  Future<void> _selectVoice(TtsVoice? voice) async {
    await ref.read(ttsVoiceControllerProvider.notifier).set(voice);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(L10n.of(context).voiceRegenerating)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final chosenLocale = ref.watch(localeControllerProvider);
    final chosenVoice = ref.watch(ttsVoiceControllerProvider);
    final voices = ref.watch(ukTtsVoicesProvider);

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          sectionLabel(l10n.settingsLanguage),
          RadioGroup<Locale?>(
            groupValue: chosenLocale,
            onChanged: (v) =>
                ref.read(localeControllerProvider.notifier).set(v),
            child: Column(
              children: [
                RadioListTile<Locale?>(
                  title: Text(l10n.languageAuto),
                  value: null,
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.languageUk),
                  value: const Locale('uk'),
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.languageEn),
                  value: const Locale('en'),
                ),
              ],
            ),
          ),
          sectionLabel(l10n.settingsVoice),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              l10n.settingsVoiceHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...voices.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            ],
            error: (_, _) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(l10n.voiceNone,
                    style: theme.textTheme.bodyMedium),
              ),
            ],
            data: (list) => _voiceTiles(l10n, theme, list, chosenVoice),
          ),
        ],
      ),
    );
  }

  List<Widget> _voiceTiles(
    L10n l10n,
    ThemeData theme,
    List<TtsVoice> list,
    TtsVoice? chosen,
  ) {
    final chosenMissing = chosen != null && !list.contains(chosen);

    Widget trailingPlay(TtsVoice? voice) {
      final active = _sampleBusy && _samplingKey == voice?.storageKey;
      return IconButton(
        icon: active
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_circle_outline),
        tooltip: l10n.previewTooltip,
        onPressed: _sampleBusy ? null : () => unawaited(_sample(voice)),
      );
    }

    return [
      RadioGroup<String?>(
        groupValue: chosen?.storageKey,
        onChanged: (key) => _selectVoice(
          key == null ? null : list.firstWhere((v) => v.storageKey == key),
        ),
        child: Column(
          children: [
            RadioListTile<String?>(
              value: null,
              title: Text(l10n.voiceDefault),
              secondary: trailingPlay(null),
            ),
            for (final v in list)
              RadioListTile<String?>(
                value: v.storageKey,
                title: Text(_voiceLabel(v)),
                subtitle: Text(v.name,
                    style: theme.textTheme.bodySmall, maxLines: 1),
                secondary: trailingPlay(v),
              ),
          ],
        ),
      ),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child:
              Text(l10n.voiceNone, style: theme.textTheme.bodyMedium),
        ),
      if (chosenMissing)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            l10n.voiceUnavailable,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
    ];
  }

  /// Читабельніша назва: прибираємо технічний префікс `uk-ua-x-`, лишаємо суть.
  String _voiceLabel(TtsVoice v) {
    var s = v.name;
    for (final p in const ['uk-ua-x-', 'uk-UA-x-', 'uk-ua-', 'uk-UA-']) {
      if (s.startsWith(p)) {
        s = s.substring(p.length);
        break;
      }
    }
    return s.replaceAll('-', ' ').replaceAll('_', ' ').trim();
  }
}
