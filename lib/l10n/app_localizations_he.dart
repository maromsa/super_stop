// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get playButton => 'שחק';

  @override
  String get settingsButton => 'הגדרות';

  @override
  String get achievementsButton => 'הישגים';

  @override
  String get homeInstructionsTooltip => 'איך משחקים?';

  @override
  String get homeInstructionsTitle => 'איך משחקים?';

  @override
  String get homeInstructionsImpulseTitle => 'משחק איפוק';

  @override
  String get homeInstructionsImpulseBody => 'חכו שהעיגול יתמלא ויהפוך לירוק ואז לחצו מהר!';

  @override
  String get homeInstructionsReactionTitle => 'מבחן תגובה';

  @override
  String get homeInstructionsReactionBody => 'חכו שהמסך יהפוך לירוק ואז לחצו הכי מהר שאפשר!';

  @override
  String get homeInstructionsStroopTitle => 'מבחן סטרופ';

  @override
  String get homeInstructionsStroopBody => 'לחצו על הכפתור שצבעו תואם לצבע המילה, לא למילה עצמה.';

  @override
  String get homeInstructionsClose => 'הבנתי';

  @override
  String get homeStatStreak => 'רצף';

  @override
  String get homeStatGoal => 'מטרה';

    @override
    String get homeStatCoins => 'מטבעות';

    @override
    String homeExperienceProgress(int current, int goal) => '$current מתוך $goal נקודות ניסיון';

    @override
    String get homeTitle => 'סופר סטופ';

  @override
  String get homeChooseChallenge => 'בחר אתגר';

  @override
  String get homeGameImpulse => 'משחק איפוק';

  @override
  String get homeGameReaction => 'מבחן תגובה';

  @override
  String get homeGameStroop => 'מבחן סטרופ';

  @override
  String get homeAdditionalTools => 'כלים נוספים';

  @override
  String get homeMoodSelectorTitle => 'בחרו את אווירת האפליקציה';

  @override
  String get homeMoodLockedMessage => 'המשיכו לשחק כדי לפתוח את מצב הרוח הזה!';

  @override
  String get homeMoodActiveBadge => 'פעיל';

  @override
  String get dailySparkFabLabel => 'הפתעה יומית';

  @override
  String get dailySparkSheetTitle => 'הניצוץ של נובה';

  @override
  String get dailySparkPrimary => 'יאללה!';

  @override
  String get dailySparkAnother => 'תנו עוד רעיון';

  @override
  String dailySparkCoinMessage(int amount) => 'קיבלתם בונוס של $amount מטבעות!';

  @override
  String get dailySparkMoveTitle => 'מסיבת תזוזה זריזה';

  @override
  String get dailySparkMoveBody => 'הפעילו שיר אהוב וקפצו או רקדו במקום ל-20 שניות.';

  @override
  String get dailySparkComplimentTitle => 'אתגר מחמאה';

  @override
  String get dailySparkComplimentBody => 'שלחו הודעה קצרה שמרימה למישהו. מחמאה אחת וזה סגור!';

  @override
  String get dailySparkFocusTitle => 'אתגר פוקוס זריז';

  @override
  String get dailySparkFocusBody => 'התחילו טיימר ריכוז קצר ותנו הכול 3 דקות.';

  @override
  String get dailySparkBreathTitle => 'Boost של נשימה';

  @override
  String get dailySparkBreathBody => 'קחו הפסקת נשימה רגועה בעזרת התרגיל המודרך.';

  @override
  String get homeToolBreathing => 'תרגיל נשימה';

  @override
  String get homeToolFocusTimer => 'טיימר ריכוז';

  @override
  String get homeToolProgress => 'לוח התקדמות';

  @override
  String get homeButtonAchievements => 'הישגים';

  @override
  String get homeButtonSettings => 'הגדרות';

  @override
  String get homeReactionModeTitle => 'בחר מצב משחק';

  @override
  String get homeReactionModeEndless => 'קלאסי (אינסופי)';

  @override
  String get homeReactionModeTest => 'מבחן (5 סיבובים)';

  @override
  String get homeImpulseModeTitle => 'בחר צורת משחק';

  @override
  String get homeImpulseModeClassic => 'קלאסי';

  @override
  String get homeImpulseModeSurvival => 'הישרדות';

  @override
  String get homeStroopModeTitle => 'בחר מצב משחק';

  @override
  String get homeStroopModeSprint => 'ספרינט (60 שניות)';

  @override
  String get homeStroopModeAccuracy => 'דיוק (טעות אחת פוסלת)';

  @override
  String get focusAppBarTitle => 'טיימר ריכוז';

  @override
  String get focusSetupTitle => 'בחרו זמן ריכוז';

  @override
  String get focusFocusMinutesLabel => 'זמן ריכוז (דקות)';

  @override
  String get focusBreakMinutesLabel => 'זמן הפסקה (דקות)';

  @override
  String get focusStartButton => 'התחל ריכוז';

  @override
  String focusSessionsCompleted(int count) => 'השלמת: $count מפגשי ריכוז';

  @override
  String focusMinutesChip(int minutes) => '$minutes דק׳';

  @override
  String get focusPhaseFocus => 'זמן ריכוז';

  @override
  String get focusPhaseBreak => 'זמן הפסקה';

  @override
  String get focusPhaseCompleted => 'הושלם!';

  @override
  String get focusPause => 'השהה';

  @override
  String get focusResume => 'המשך';

  @override
  String get focusCompletionMessage => 'כל הכבוד! השלמת מפגש ריכוז!';

  @override
  String get focusTakeBreak => 'קח הפסקה';

  @override
  String get focusBackToMenu => 'חזור לתפריט';

  @override
  String get progressAppBarTitle => 'לוח התקדמות';

  @override
  String get progressStreakSubtitle => 'ימים ברצף';

  @override
  String get progressDailyGoalTitle => 'מטרה יומית';

  @override
  String progressDailyGoalLabel(int played, int goal) => '$played / $goal משחקים';

  @override
  String progressDailyGoalFocus(int minutes) => '$minutes דקות ריכוז היום';

  @override
  String get progressStatsCoins => 'מטבעות';

  @override
  String get progressStatsGamesToday => 'משחקים היום';

  @override
  String get progressStatsFocusToday => 'דקות ריכוז';

  @override
  String get progressStatsWeeklyGames => 'סה"כ משחקים השבוע';

  @override
  String get progressStatsWeeklyFocus => 'סה"כ דקות השבוע';

  @override
  String get progressWeeklyGamesTitle => 'משחקים השבוע';

  @override
  String get progressAchievementsTitle => 'הישגים';

  @override
    String get progressAchievementsButton => 'צפה בכל ההישגים';

    @override
    String get achievementUnknown => 'הישג חדש!';

  @override
  String get moodCheckInTitle => 'בדיקת מצב רוח';

  @override
  String get moodCheckInPrompt => 'בחרו את המצב שמרגיש הכי מתאים לרגע.';

  @override
  String get moodCheckInButton => 'סמן מצב רוח';

  @override
  String get moodCheckInToday => 'כבר סומן היום';

  @override
  String get moodCheckInThanks => 'תודה! המצב נשמר.';

  @override
  String get moodCheckInLastTitle => 'מצב אחרון';

  @override
  String moodCheckInLastTime(String time) => 'נרשם לאחרונה בשעה $time';

  @override
  String get moodDistributionEmpty => 'סמנו מצב רוח כדי לראות תצוגה שבועית.';

  @override
  String get moodDistributionTitle => 'מצבי רוח בולטים השבוע';

  @override
  String get moodHappy => 'שמח';

  @override
  String get moodAngry => 'כועס';

  @override
  String get moodSad => 'עצוב';

  @override
  String get moodAnxious => 'לחוץ';

  @override
  String get moodCalm => 'רגוע';

  @override
  String get moodExcited => 'נרגש';

  @override
  String get onboardingSkip => 'דלג';

  @override
  String get onboardingWelcomeTitle => 'ברוכים הבאים ל-Super Stop!';

  @override
  String get onboardingWelcomeBody => 'מאמנים שליטה עצמית, ריכוז ואיזון רגשי עם משחקים מותאמים לילדים עם ADHD.';

  @override
  String get onboardingFeatureTitle => 'מה מחכה לכם?';

  @override
  String get onboardingFeatureGames => 'משחקי אימפולסיביות כיפיים לתרגול יומי';

  @override
  String get onboardingFeatureFocus => 'מפגשי ריכוז קצרים עם הפסקות מודרכות';

  @override
  String get onboardingFeatureRewards => 'מטבעות, רצפים והישגים צבעוניים';

  @override
  String get onboardingFeatureProgress => 'לוח התקדמות עם סטטיסטיקות שבועיות';

  @override
  String get onboardingMoodTitle => 'איך אתם מרגישים היום?';

  @override
  String get onboardingMoodSubtitle => 'בחרו אמוג׳י כדי להתחיל את ההרפתקה.';

  @override
  String get onboardingBack => 'חזרה';

  @override
  String get onboardingNext => 'הבא';

  @override
    String get onboardingMoodPrompt => 'בחרו מצב רוח כדי להתחיל';

    @override
    String get impulseGameOverTitle => 'המשחק הסתיים!';

    @override
    String impulseFinalScore(int score) => 'ניקוד סופי: $score';

    @override
    String get impulseReturnHome => 'חזרה למסך הבית';

    @override
    String impulseComboLabel(int combo) => 'x$combo רצף!';

    @override
    String get reactionTestCompleteTitle => 'הבדיקה הסתיימה!';

    @override
    String reactionTestCompleteSummary(int best, int worst, int average) => 'הטוב ביותר: $best מילישניות\nהחלש ביותר: $worst מילישניות\nממוצע: $average מילישניות\n\nלחצו כדי לשחק שוב';

    @override
    String get routerNotFound => 'העמוד לא נמצא';
}
