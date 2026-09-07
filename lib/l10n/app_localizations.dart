import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// Назва застосунку (перемикач задач, заголовок)
  ///
  /// In uk, this message translates to:
  /// **'Хвилина мовчання'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In uk, this message translates to:
  /// **'Налаштування'**
  String get settingsTooltip;

  /// No description provided for @errorPrefix.
  ///
  /// In uk, this message translates to:
  /// **'Помилка: {error}'**
  String errorPrefix(String error);

  /// Підпис роздільника перед власними нагадуваннями
  ///
  /// In uk, this message translates to:
  /// **'Нагадування'**
  String get remindersSection;

  /// Напис на кнопці додавання
  ///
  /// In uk, this message translates to:
  /// **'Нагадування'**
  String get fabNewReminder;

  /// No description provided for @emptyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Немає нагадувань'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In uk, this message translates to:
  /// **'Додайте нагадування кнопкою внизу.'**
  String get emptyBody;

  /// No description provided for @editorNewTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нове нагадування'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати'**
  String get editorEditTitle;

  /// No description provided for @save.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In uk, this message translates to:
  /// **'Видалити'**
  String get delete;

  /// No description provided for @fieldTime.
  ///
  /// In uk, this message translates to:
  /// **'Час'**
  String get fieldTime;

  /// No description provided for @fieldName.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get fieldName;

  /// No description provided for @fieldBody.
  ///
  /// In uk, this message translates to:
  /// **'Текст сповіщення'**
  String get fieldBody;

  /// No description provided for @fieldBodyHelper.
  ///
  /// In uk, this message translates to:
  /// **'Необовʼязково — показується під назвою у шторці'**
  String get fieldBodyHelper;

  /// No description provided for @previewTooltip.
  ///
  /// In uk, this message translates to:
  /// **'Прослухати'**
  String get previewTooltip;

  /// No description provided for @speakSwitchTitle.
  ///
  /// In uk, this message translates to:
  /// **'Озвучити сповіщення'**
  String get speakSwitchTitle;

  /// No description provided for @speakSwitchOnHint.
  ///
  /// In uk, this message translates to:
  /// **'Програти «гонг + текст» при спрацюванні'**
  String get speakSwitchOnHint;

  /// No description provided for @speakSwitchOffHint.
  ///
  /// In uk, this message translates to:
  /// **'Додайте текст сповіщення, щоб увімкнути'**
  String get speakSwitchOffHint;

  /// No description provided for @volumeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Гучність озвучення: {percent}%'**
  String volumeLabel(int percent);

  /// Підпис під повзунком гучності: канал використовує потік будильника
  ///
  /// In uk, this message translates to:
  /// **'Звучить через гучність будильника пристрою — не залежить від гучності сповіщень і беззвучного режиму.'**
  String get volumeAlarmHint;

  /// No description provided for @repeatTitle.
  ///
  /// In uk, this message translates to:
  /// **'Повторювати'**
  String get repeatTitle;

  /// No description provided for @repeatEveryDay.
  ///
  /// In uk, this message translates to:
  /// **'Щодня'**
  String get repeatEveryDay;

  /// No description provided for @repeatWeekdays.
  ///
  /// In uk, this message translates to:
  /// **'По буднях'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekend.
  ///
  /// In uk, this message translates to:
  /// **'На вихідних'**
  String get repeatWeekend;

  /// No description provided for @repeatNever.
  ///
  /// In uk, this message translates to:
  /// **'Не повторюється'**
  String get repeatNever;

  /// No description provided for @previewTooLong.
  ///
  /// In uk, this message translates to:
  /// **'Озвучення триває {seconds} с. У сповіщенні воно буде обрізане до ~30 с — скоротіть текст.'**
  String previewTooLong(int seconds);

  /// No description provided for @previewFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося озвучити: {message}'**
  String previewFailed(String message);

  /// No description provided for @deleteTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити нагадування?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In uk, this message translates to:
  /// **'«{name}» буде видалено.'**
  String deleteBody(String name);

  /// Дефолтна назва нового нагадування
  ///
  /// In uk, this message translates to:
  /// **'Сповіщення'**
  String get newReminderDefaultName;

  /// Назва вбудованого нагадування
  ///
  /// In uk, this message translates to:
  /// **'Хвилина мовчання'**
  String get builtInTitle;

  /// Текст, що озвучується й показується в тілі вбудованого нагадування
  ///
  /// In uk, this message translates to:
  /// **'УВАГА! Оголошується загальнонаціональна хвилина мовчання.'**
  String get builtInAnnouncement;

  /// No description provided for @chanSilenceName.
  ///
  /// In uk, this message translates to:
  /// **'Хвилина мовчання'**
  String get chanSilenceName;

  /// No description provided for @chanSilenceDesc.
  ///
  /// In uk, this message translates to:
  /// **'Загальнонаціональна хвилина мовчання'**
  String get chanSilenceDesc;

  /// No description provided for @chanCustomName.
  ///
  /// In uk, this message translates to:
  /// **'Власні нагадування'**
  String get chanCustomName;

  /// No description provided for @chanCustomDesc.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування, які ви додали самостійно'**
  String get chanCustomDesc;

  /// No description provided for @chanPreName.
  ///
  /// In uk, this message translates to:
  /// **'Хвилина мовчання — попередження'**
  String get chanPreName;

  /// No description provided for @chanPreDesc.
  ///
  /// In uk, this message translates to:
  /// **'Сповіщення за 10 секунд до хвилини мовчання'**
  String get chanPreDesc;

  /// No description provided for @chanEndName.
  ///
  /// In uk, this message translates to:
  /// **'Хвилина мовчання — завершення'**
  String get chanEndName;

  /// No description provided for @chanEndDesc.
  ///
  /// In uk, this message translates to:
  /// **'Сигнал про завершення хвилини мовчання'**
  String get chanEndDesc;

  /// No description provided for @spokenGroupName.
  ///
  /// In uk, this message translates to:
  /// **'Озвучені нагадування'**
  String get spokenGroupName;

  /// No description provided for @spokenChannelName.
  ///
  /// In uk, this message translates to:
  /// **'Озвучення: {title}'**
  String spokenChannelName(String title);

  /// No description provided for @spokenChannelDesc.
  ///
  /// In uk, this message translates to:
  /// **'Озвучене нагадування «{title}»'**
  String spokenChannelDesc(String title);

  /// No description provided for @preNotifTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування про хвилину мовчання'**
  String get preNotifTitle;

  /// No description provided for @endNotifTitle.
  ///
  /// In uk, this message translates to:
  /// **'Хвилину мовчання завершено'**
  String get endNotifTitle;

  /// No description provided for @reminderFallbackTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування'**
  String get reminderFallbackTitle;

  /// No description provided for @actionOk.
  ///
  /// In uk, this message translates to:
  /// **'Гаразд'**
  String get actionOk;

  /// No description provided for @actionSnooze.
  ///
  /// In uk, this message translates to:
  /// **'Відкласти'**
  String get actionSnooze;

  /// No description provided for @weekdayShort1.
  ///
  /// In uk, this message translates to:
  /// **'Пн'**
  String get weekdayShort1;

  /// No description provided for @weekdayShort2.
  ///
  /// In uk, this message translates to:
  /// **'Вт'**
  String get weekdayShort2;

  /// No description provided for @weekdayShort3.
  ///
  /// In uk, this message translates to:
  /// **'Ср'**
  String get weekdayShort3;

  /// No description provided for @weekdayShort4.
  ///
  /// In uk, this message translates to:
  /// **'Чт'**
  String get weekdayShort4;

  /// No description provided for @weekdayShort5.
  ///
  /// In uk, this message translates to:
  /// **'Пт'**
  String get weekdayShort5;

  /// No description provided for @weekdayShort6.
  ///
  /// In uk, this message translates to:
  /// **'Сб'**
  String get weekdayShort6;

  /// No description provided for @weekdayShort7.
  ///
  /// In uk, this message translates to:
  /// **'Нд'**
  String get weekdayShort7;

  /// No description provided for @settingsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Налаштування'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In uk, this message translates to:
  /// **'Мова'**
  String get settingsLanguage;

  /// No description provided for @languageAuto.
  ///
  /// In uk, this message translates to:
  /// **'Авто (за регіоном)'**
  String get languageAuto;

  /// No description provided for @languageUk.
  ///
  /// In uk, this message translates to:
  /// **'Українська'**
  String get languageUk;

  /// No description provided for @languageEn.
  ///
  /// In uk, this message translates to:
  /// **'English'**
  String get languageEn;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'uk':
      return L10nUk();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
