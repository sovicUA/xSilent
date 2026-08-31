import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final chosen = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.settingsLanguage.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          RadioGroup<Locale?>(
            groupValue: chosen,
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
        ],
      ),
    );
  }
}
