# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

"Хвилина мовчання" (xSilent) — a Flutter reminder app (Android-first, iOS planned). It has one built-in reminder ("Moment of Silence", daily 09:00) plus user-defined reminders. Each reminder can speak its text aloud at fire time. Fully offline; no backend, no analytics, no network.

Design/decision history and rationale live in **[DECISIONS.md](DECISIONS.md)** (Ukrainian, chronological). Read it for context on *why* things are the way they are before making architectural changes. User-facing package structure is in [README.md](README.md). Play Store release process is in [store/README.md](store/README.md).

Code, comments, commit messages, and docs are in **Ukrainian**. Keep new comments/strings Ukrainian.

## Commands

`flutter` / `dart` are expected on PATH (this machine: `D:\src\flutter\bin`). The Windows Android toolchain is wired via `flutter config` (`--android-sdk`, `--jdk-dir` → JDK 21); no per-shell env vars needed.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates lib/database/database.g.dart
flutter gen-l10n                                            # regenerates lib/l10n/app_localizations*.dart
flutter analyze
flutter test
flutter test test/wav_test.dart                            # single file
flutter test --plain-name "nextInstanceOf"                 # single test/group by name
flutter run                                                 # needs a device/emulator
flutter build apk --debug --target-platform android-arm64  # fast device build
flutter build appbundle --release                          # AAB (debug-signed unless android/key.properties exists)
dart run flutter_launcher_icons                            # after changing assets/icon/*
```

**Generated files are committed** (`lib/database/database.g.dart`, `lib/l10n/app_localizations*.dart`). CI fails if they drift, so after editing `lib/database/database.dart` tables or any `lib/l10n/*.arb` you must regenerate and commit. The l10n **template is `lib/l10n/app_uk.arb`** (uk), not `app_en.arb`.

`dart format` is intentionally NOT enforced (a one-time reformat is deferred — see DECISIONS.md). Don't reformat untouched files.

### On-device testing (Android)

The "announcement as channel sound" path can only be verified on a real device — inspect with `adb shell dumpsys alarm | grep xsilent` (scheduled fires) and `adb shell dumpsys notification` (channels + `mSound=content://...`). The drift DB is at `/data/data/ua.org.sovic.xsilent/app_flutter/xsilent.sqlite` (pull via `adb exec-out run-as`).

`android/gradle.properties` sets `kotlin.incremental=false` deliberately (Windows `.tab` cache lock failures); keep it.

## Architecture

### Data flow

`AppDatabase` (drift, one `Reminders` table) → **`RemindersRepository`** → Riverpod providers (`providers.dart`) → UI (`ConsumerWidget`s). `remindersProvider` is a `StreamProvider` over `watchAll()` so the list is reactive.

**`RemindersRepository` is the only place reminders may be mutated.** Every `create`/`update`/`setEnabled`/`delete` immediately calls into `NotificationService` to (re)schedule or purge. Writing to the DB directly anywhere else will desync scheduled notifications.

### `reconcile()` — the bootstrap

`RemindersRepository.reconcile()` is the startup and locale-change entry point: it (1) `_notifications.init()` **first** (channels + timezones — must precede any `sync()`, incl. the one inside `create()`), (2) seeds the built-in reminder if the DB is empty, (3) re-localizes the built-in's title/body if still at any locale's default, (4) `syncAll()`, (5) `sweepLegacyChannels()`.

It is invoked only from `main.dart` via `container.listen(effectiveLocaleProvider, fireImmediately: true)`, funnelled through a single global `Future` chain (`_reconcileChain`) so a stale re-schedule (queued with an old locale) can't clobber a fresh one. Errors are logged, never fatal. `main()` does **not** await notification init separately.

### Notifications = "announcement as channel sound" (Android)

This is the core, non-obvious mechanism (`NotificationService` + `AnnouncementService` + `SoundStore` + `utils/wav.dart` + `android/.../SoundStore.kt`):

1. On save/preview, `AnnouncementService` synthesizes the reminder body via `flutter_tts.synthesizeToFile`, then in pure Dart mixes **gong + 400 ms gap + speech (+ optional metronome tail)** into one 16-bit mono WAV (`wav.dart`).
2. Native `SoundStore` (MethodChannel `xsilent/sound_store`) writes that WAV into Android `MediaStore` (`Notifications/xSilent`, `IS_NOTIFICATION=1`) → `content://` URI. No runtime permission (app-owned files, Android 10+).
3. A per-reminder notification channel `spoken_r{id}_{hash}` is created with that URI as its sound. The system then plays the whole announcement as the notification sound — independently of background-execution limits, silent mode, etc.
4. The `hash` is a deterministic **FNV-1a 32-bit** over `text | volume | gong | ticking | _channelFormatVersion` (Dart's `String.hashCode` is per-isolate randomized — unusable here). Same inputs → same channel id → `sync()` skips regeneration. Changing text/volume → new hash → new channel+file, old ones pruned.

**Channel audio attributes are immutable after creation.** All channels use the **alarm** audio stream (`AudioAttributesUsage.alarm`) so volume follows the alarm slider, not notifications, and ignores silent mode. Any change to stream/format needs a *new channel id*: hence the `_v3` suffixes on static channel ids, `_channelFormatVersion` in the announcement hash, and `_legacyChannelIds` + `sweepLegacyChannels()` (which also runs a second pass after `syncAll` because the plugin can resurrect an old channel while re-scheduling stored notifications, e.g. after `MY_PACKAGE_REPLACED`).

Non-speaking / non-ticking reminders (or when synthesis throws `AnnouncementException`) fall back to a static channel (`silenceChannelId` / `customChannelId`).

### Scheduling

One `zonedSchedule` per active weekday, `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime` (weekly repeat, no manual next-fire math — see `nextInstanceOf` in `notification_service.dart`, `@visibleForTesting`).

Notification ID scheme (all derived, no storage):
- main: `reminderId * 8 + weekday`
- snooze: `reminderId * 8` (weekday 0 slot)
- pre-signal: `10000000 + reminderId * 8 + weekday`
- end-of-silence (built-in only): `8100000 + weekday`

The **built-in** reminder fires a 3-part sequence per day: pre-signal (T−`preLeadSeconds`) → main announcement (T, main gong + TTS, optionally + metronome for the full minute) → end signal (T+1 min). Custom reminders: main + optional pre-signal. `_cancelNotifications` takes `isBuiltIn` — it must NOT touch the global built-in pre/end ids when syncing a custom reminder.

### Background isolate

`notificationActionCallback` (`@pragma('vm:entry-point')`, top-level) handles the "Snooze" banner button. When the app is dead this runs in a fresh isolate with no plugin/timezone context, so `snooze()` calls `_initCore()` (timezones + `_plugin.initialize`, no channel work) before `zonedSchedule`. The reminder locale is carried in the notification payload JSON and resolved via `lookupL10n`.

### Localization

`effectiveLocaleProvider` (`app_settings.dart`) is the **single source of truth** for both `MaterialApp.locale` and all non-widget code: explicit user choice (`shared_preferences` key `app_locale`), else region auto (`countryCode ∈ {UA, RU, BY}` → `uk`, else `en`). `deviceLocalesProvider` uses `WidgetsBindingObserver.didChangeLocales` to survive the Android startup race where `PlatformDispatcher.locales` still reports `ro.product.locale`.

`L10n` (generated) + a top-level synchronous `lookupL10n(Locale)` + `l10nProvider` give string access from providers and the background isolate — no `Localizations.of(context)` outside widgets.

### Database migrations

`schemaVersion` currently **6**; migrations are `addColumn`-only (plus one data patch at v6). Bump the version and add an `if (from < N)` branch when adding a column.

### Content policy

`ProfanityFilter.containsProfanity` gates announcement body text on save/preview (Google Play age rating). Root-stem matching, obfuscation-resistant.

### Platform notes

- **Android**: primary target. `SoundStore` / MediaStore path is Android-only.
- **iOS**: notifications are wired (`AppDelegate.swift` `UNUserNotificationCenter` delegate) but the spoken path is not implemented. `SoundStore.put` throws `UnsupportedError` (not `AnnouncementException`), which `sync()` does not catch — so a speaking reminder currently makes `reconcile()` throw on iOS. Building out the iOS path (or guarding the synth path by platform) is an open task.
- Small status-bar icon `ic_stat_xsilent` must stay alpha-only; raw audio in `res/raw/` is referenced by name from Dart so it needs `res/raw/keep.xml` to survive the release resource shrinker.

## Release

Release signing reads `android/key.properties` (gitignored); absent → debug-signed so `flutter run --release` and CI still work. CI: `.github/workflows/ci.yml` (analyze + test + generated-file check + AAB compile on every push/PR); `release.yml` (tag `v*` → signed AAB → Play `internal` track). Bump `version:` in `pubspec.yaml` before tagging.
