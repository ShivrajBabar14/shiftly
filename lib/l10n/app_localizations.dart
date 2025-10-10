import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';

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
    Locale('de'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt')
  ];

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employee;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shiftwise'**
  String get appTitle;

  /// No description provided for @unlockPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features with Shiftwise Pro'**
  String get unlockPremiumTitle;

  /// No description provided for @featureUnlimitedEmployees.
  ///
  /// In en, this message translates to:
  /// **'Add unlimited employees'**
  String get featureUnlimitedEmployees;

  /// No description provided for @featureAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get featureAutoBackup;

  /// No description provided for @featureAdvancedScheduling.
  ///
  /// In en, this message translates to:
  /// **'Access advanced shift scheduling'**
  String get featureAdvancedScheduling;

  /// No description provided for @featureMarkAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get featureMarkAttendance;

  /// No description provided for @continueFreeButton.
  ///
  /// In en, this message translates to:
  /// **'Continue Free'**
  String get continueFreeButton;

  /// No description provided for @goProButton.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goProButton;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @congratulationsText.
  ///
  /// In en, this message translates to:
  /// **'You have now successfully subscribed to Shiftwise Pro.'**
  String get congratulationsText;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'No backup found'**
  String get notFound;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of your data to prevent loss.'**
  String get backupDescription;

  /// No description provided for @backupPath.
  ///
  /// In en, this message translates to:
  /// **'Backup Path'**
  String get backupPath;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get restoreBackup;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Please try again.'**
  String get backupFailed;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get notSelected;

  /// No description provided for @invalidFilePath.
  ///
  /// In en, this message translates to:
  /// **'Invalid file path.'**
  String get invalidFilePath;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup.'**
  String get restoreFailed;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @annually.
  ///
  /// In en, this message translates to:
  /// **'Annually'**
  String get annually;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a subscription plan that suits your needs.'**
  String get subscriptionSubtitle;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Google Play services not available'**
  String get service;

  /// No description provided for @shiftwisePro.
  ///
  /// In en, this message translates to:
  /// **'Shiftwise Pro'**
  String get shiftwisePro;

  /// No description provided for @featureUnlimitedEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Employee Access'**
  String get featureUnlimitedEmployeesTitle;

  /// No description provided for @featureUnlimitedEmployeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add more than 5 employees to your team with a paid plan'**
  String get featureUnlimitedEmployeesSubtitle;

  /// No description provided for @featureAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get featureAutoBackupTitle;

  /// No description provided for @featureAutoBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe with automatic backup feature'**
  String get featureAutoBackupSubtitle;

  /// No description provided for @featureAdvancedSchedulingTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Shift Scheduling'**
  String get featureAdvancedSchedulingTitle;

  /// No description provided for @featureAdvancedSchedulingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create shifts for the upcoming weeks in advance.'**
  String get featureAdvancedSchedulingSubtitle;

  /// No description provided for @featureMarkAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get featureMarkAttendanceTitle;

  /// No description provided for @featureMarkAttendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of daily attendance of your team.'**
  String get featureMarkAttendanceSubtitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Write Feedback'**
  String get feedback;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @noMailApp.
  ///
  /// In en, this message translates to:
  /// **'No mail app found on this device.'**
  String get noMailApp;

  /// No description provided for @noGmailApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to open Gmail app.'**
  String get noGmailApp;

  /// No description provided for @noPlayStoreApp.
  ///
  /// In en, this message translates to:
  /// **'Play Store app not found on this device.'**
  String get noPlayStoreApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by Linear Apps'**
  String get developedBy;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactEmail;

  /// No description provided for @allEmployees.
  ///
  /// In en, this message translates to:
  /// **'All Employees'**
  String get allEmployees;

  /// No description provided for @failPlaystore.
  ///
  /// In en, this message translates to:
  /// **'Failed to open Play Store.'**
  String get failPlaystore;

  /// No description provided for @failshare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share the app.'**
  String get failshare;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @errorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating employee:'**
  String get errorUpdate;

  /// No description provided for @alreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Employee name already exists'**
  String get alreadyExist;

  /// No description provided for @alreadyExistId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID already exists'**
  String get alreadyExistId;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @empName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get empName;

  /// No description provided for @empId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get empId;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @shiftDetails.
  ///
  /// In en, this message translates to:
  /// **'Shift Details'**
  String get shiftDetails;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @shareImgText.
  ///
  /// In en, this message translates to:
  /// **'Employee Shift for'**
  String get shareImgText;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @shiftShare.
  ///
  /// In en, this message translates to:
  /// **'employee_shift_shared'**
  String get shiftShare;

  /// No description provided for @img.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get img;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @shareImg.
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get shareImg;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @removeEmployee.
  ///
  /// In en, this message translates to:
  /// **'Remove Employee'**
  String get removeEmployee;

  /// No description provided for @removeEmployeeText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove'**
  String get removeEmployeeText;

  /// No description provided for @removeEmployeeText2.
  ///
  /// In en, this message translates to:
  /// **'from this week\'s shift table?'**
  String get removeEmployeeText2;

  /// No description provided for @remains.
  ///
  /// In en, this message translates to:
  /// **'(Employee will remain in your main employee list)'**
  String get remains;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @mondayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayAbbrc;

  /// No description provided for @tuesdayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayAbbrc;

  /// No description provided for @wednesdayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayAbbrc;

  /// No description provided for @thursdayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayAbbrc;

  /// No description provided for @fridayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayAbbrc;

  /// No description provided for @saturdayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayAbbrc;

  /// No description provided for @sundayAbbrc.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayAbbrc;

  /// No description provided for @mondayAbbr.
  ///
  /// In en, this message translates to:
  /// **'mon'**
  String get mondayAbbr;

  /// No description provided for @tuesdayAbbr.
  ///
  /// In en, this message translates to:
  /// **'tue'**
  String get tuesdayAbbr;

  /// No description provided for @wednesdayAbbr.
  ///
  /// In en, this message translates to:
  /// **'wed'**
  String get wednesdayAbbr;

  /// No description provided for @thursdayAbbr.
  ///
  /// In en, this message translates to:
  /// **'thu'**
  String get thursdayAbbr;

  /// No description provided for @fridayAbbr.
  ///
  /// In en, this message translates to:
  /// **'fri'**
  String get fridayAbbr;

  /// No description provided for @saturdayAbbr.
  ///
  /// In en, this message translates to:
  /// **'sat'**
  String get saturdayAbbr;

  /// No description provided for @sundayAbbr.
  ///
  /// In en, this message translates to:
  /// **'sun'**
  String get sundayAbbr;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get addShift;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @shiftName.
  ///
  /// In en, this message translates to:
  /// **'Shift Name'**
  String get shiftName;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @markAttendanceLimit.
  ///
  /// In en, this message translates to:
  /// **'(Attendance can only be marked for today and prior dates.)'**
  String get markAttendanceLimit;

  /// No description provided for @shiftWarning.
  ///
  /// In en, this message translates to:
  /// **'Please enter a shift name or time range.'**
  String get shiftWarning;

  /// No description provided for @emptyTable.
  ///
  /// In en, this message translates to:
  /// **'Your shift tracking will appear here.'**
  String get emptyTable;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Tap below to begin.'**
  String get begin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Advanced Shift Scheduling'**
  String get unlock;

  /// No description provided for @proVersion.
  ///
  /// In en, this message translates to:
  /// **'You can create shifts for the upcoming or previous weeks with the Pro version.'**
  String get proVersion;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select Employees'**
  String get select;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'de', 'es', 'ja', 'ko', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'de': return AppLocalizationsDe();
    case 'es': return AppLocalizationsEs();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
