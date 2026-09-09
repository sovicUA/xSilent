// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moment of Silence';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get remindersSection => 'Reminders';

  @override
  String get fabNewReminder => 'Reminder';

  @override
  String get emptyTitle => 'No reminders';

  @override
  String get emptyBody => 'Add a reminder with the button below.';

  @override
  String get editorNewTitle => 'New reminder';

  @override
  String get editorEditTitle => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get fieldTime => 'Time';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldBody => 'Notification text';

  @override
  String get fieldBodyHelper => 'Optional — shown below the name in the shade';

  @override
  String get previewTooltip => 'Preview';

  @override
  String get speakSwitchTitle => 'Read aloud';

  @override
  String get speakSwitchOnHint => 'Play “gong + text” when it fires';

  @override
  String get speakSwitchOffHint => 'Add notification text to enable';

  @override
  String volumeLabel(int percent) {
    return 'Announcement volume: $percent%';
  }

  @override
  String get volumeAlarmHint =>
      'Plays at the device’s alarm volume — independent of the notification volume and silent mode.';

  @override
  String get tickSwitchTitle => 'Metronome during the moment of silence';

  @override
  String get tickSwitchHint =>
      'A quiet tick every second — from the announcement to the end cue';

  @override
  String get preSignalSwitchTitle => 'Advance signal';

  @override
  String get preSignalSwitchHint => 'A gong a few seconds before the reminder';

  @override
  String preLeadLabel(int seconds) {
    return '$seconds s before the reminder';
  }

  @override
  String get repeatTitle => 'Repeat';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekend => 'Weekends';

  @override
  String get repeatNever => 'Doesn’t repeat';

  @override
  String previewTooLong(int seconds) {
    return 'The announcement is $seconds s long. It will be cut to ~30 s in the notification — shorten the text.';
  }

  @override
  String previewFailed(String message) {
    return 'Couldn’t read aloud: $message';
  }

  @override
  String get bodyProfanityError =>
      'The text contains profanity — remove it to save.';

  @override
  String get deleteTitle => 'Delete reminder?';

  @override
  String deleteBody(String name) {
    return '“$name” will be deleted.';
  }

  @override
  String get newReminderDefaultName => 'Notification';

  @override
  String get builtInTitle => 'Moment of Silence';

  @override
  String get builtInAnnouncement =>
      'Attention. The nationwide moment of silence begins now.';

  @override
  String get chanSilenceName => 'Moment of Silence';

  @override
  String get chanSilenceDesc => 'The nationwide moment of silence';

  @override
  String get chanCustomName => 'Your reminders';

  @override
  String get chanCustomDesc => 'Reminders you added yourself';

  @override
  String get chanPreName => 'Advance signal';

  @override
  String get chanPreDesc => 'A gong shortly before a reminder fires';

  @override
  String get chanEndName => 'Moment of Silence — end';

  @override
  String get chanEndDesc => 'Signal that the moment of silence has ended';

  @override
  String get spokenGroupName => 'Spoken reminders';

  @override
  String spokenChannelName(String title) {
    return 'Announcement: $title';
  }

  @override
  String spokenChannelDesc(String title) {
    return 'Spoken reminder “$title”';
  }

  @override
  String get preNotifTitle => 'Moment of silence reminder';

  @override
  String get endNotifTitle => 'Moment of silence ended';

  @override
  String get reminderFallbackTitle => 'Reminder';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSnooze => 'Snooze';

  @override
  String get weekdayShort1 => 'Mon';

  @override
  String get weekdayShort2 => 'Tue';

  @override
  String get weekdayShort3 => 'Wed';

  @override
  String get weekdayShort4 => 'Thu';

  @override
  String get weekdayShort5 => 'Fri';

  @override
  String get weekdayShort6 => 'Sat';

  @override
  String get weekdayShort7 => 'Sun';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageAuto => 'Auto (by region)';

  @override
  String get languageUk => 'Українська';

  @override
  String get languageEn => 'English';

  @override
  String get settingsVoice => 'Announcement voice';

  @override
  String get settingsVoiceHint =>
      'Changes the voice for all reminders. Network voices are hidden — they don’t work offline.';

  @override
  String get voiceDefault => 'Default';

  @override
  String get voiceNone =>
      'No Ukrainian voices found in the engine — using the default.';

  @override
  String get voiceUnavailable =>
      'The selected voice is unavailable on this device';

  @override
  String get voiceSampleText =>
      'This is a sample of the selected announcement voice.';

  @override
  String get voiceRegenerating => 'Updating reminder announcements…';
}
