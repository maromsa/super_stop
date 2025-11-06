import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// No description provided for @achievementsButton.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsButton;

  String get homeInstructionsTooltip;
  String get homeInstructionsTitle;
  String get homeInstructionsImpulseTitle;
  String get homeInstructionsImpulseBody;
  String get homeInstructionsReactionTitle;
  String get homeInstructionsReactionBody;
  String get homeInstructionsStroopTitle;
  String get homeInstructionsStroopBody;
  String get homeInstructionsClose;
  String get homeStatStreak;
    String get homeStatGoal;
    String get homeStatCoins;
    String homeExperienceProgress(int current, int goal);
  String get homeTitle;
  String get homeChooseChallenge;
  String get homeGameImpulse;
  String get homeGameReaction;
  String get homeGameStroop;
  String get homeAdditionalTools;
  String get homeMoodSelectorTitle;
  String get homeMoodLockedMessage;
  String get homeMoodActiveBadge;
  String get dailySparkFabLabel;
  String get dailySparkSheetTitle;
  String get dailySparkPrimary;
  String get dailySparkAnother;
  String dailySparkCoinMessage(int amount);
  String get dailySparkMoveTitle;
  String get dailySparkMoveBody;
  String get dailySparkComplimentTitle;
  String get dailySparkComplimentBody;
  String get dailySparkFocusTitle;
  String get dailySparkFocusBody;
  String get dailySparkBreathTitle;
  String get dailySparkBreathBody;
  String get homeToolBreathing;
  String get homeToolFocusTimer;
  String get homeToolProgress;
  String get homeButtonAchievements;
  String get homeButtonSettings;
  String get homeReactionModeTitle;
  String get homeReactionModeEndless;
  String get homeReactionModeTest;
  String get homeImpulseModeTitle;
  String get homeImpulseModeClassic;
  String get homeImpulseModeSurvival;
  String get homeStroopModeTitle;
  String get homeStroopModeSprint;
  String get homeStroopModeAccuracy;

  String get focusAppBarTitle;
  String get focusSetupTitle;
  String get focusFocusMinutesLabel;
  String get focusBreakMinutesLabel;
  String get focusStartButton;
  String focusSessionsCompleted(int count);
  String focusMinutesChip(int minutes);
  String get focusPhaseFocus;
  String get focusPhaseBreak;
  String get focusPhaseCompleted;
  String get focusPause;
  String get focusResume;
  String get focusCompletionMessage;
  String get focusTakeBreak;
  String get focusBackToMenu;

  String get progressAppBarTitle;
  String get progressStreakSubtitle;
  String get progressDailyGoalTitle;
  String progressDailyGoalLabel(int played, int goal);
  String progressDailyGoalFocus(int minutes);
  String get progressStatsCoins;
  String get progressStatsGamesToday;
  String get progressStatsFocusToday;
    String get progressStatsWeeklyGames;
    String get progressStatsWeeklyFocus;
    String get progressWeeklyGamesTitle;
    String get progressAchievementsTitle;
    String get progressAchievementsButton;
    String get achievementUnknown;

  String get moodCheckInTitle;
  String get moodCheckInPrompt;
  String get moodCheckInButton;
  String get moodCheckInToday;
  String get moodCheckInThanks;
  String get moodCheckInLastTitle;
  String moodCheckInLastTime(String time);
  String get moodDistributionEmpty;
  String get moodDistributionTitle;
  String get moodHappy;
  String get moodAngry;
  String get moodSad;
  String get moodAnxious;
  String get moodCalm;
  String get moodExcited;

  String get onboardingSkip;
  String get onboardingWelcomeTitle;
  String get onboardingWelcomeBody;
  String get onboardingFeatureTitle;
  String get onboardingFeatureGames;
  String get onboardingFeatureFocus;
  String get onboardingFeatureRewards;
    String get onboardingFeatureProgress;
    String get onboardingMoodTitle;
    String get onboardingMoodSubtitle;
    String get onboardingBack;
    String get onboardingNext;
    String get onboardingMoodPrompt;

    String get impulseGameOverTitle;
    String impulseFinalScore(int score);
    String get impulseReturnHome;
    String impulseComboLabel(int combo);

    String get reactionTestCompleteTitle;
    String reactionTestCompleteSummary(int best, int worst, int average);

    String get routerNotFound;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'he': return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
