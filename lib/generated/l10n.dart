// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Employees`
  String get employee {
    return Intl.message('Employees', name: 'employee', desc: '', args: []);
  }

  /// `Add Employee`
  String get addEmployee {
    return Intl.message(
      'Add Employee',
      name: 'addEmployee',
      desc: '',
      args: [],
    );
  }

  /// `Shiftwise`
  String get appTitle {
    return Intl.message('Shiftwise', name: 'appTitle', desc: '', args: []);
  }

  /// `Unlock premium features with Shiftwise Pro`
  String get unlockPremiumTitle {
    return Intl.message(
      'Unlock premium features with Shiftwise Pro',
      name: 'unlockPremiumTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add unlimited employees`
  String get featureUnlimitedEmployees {
    return Intl.message(
      'Add unlimited employees',
      name: 'featureUnlimitedEmployees',
      desc: '',
      args: [],
    );
  }

  /// `Auto Backup`
  String get featureAutoBackup {
    return Intl.message(
      'Auto Backup',
      name: 'featureAutoBackup',
      desc: '',
      args: [],
    );
  }

  /// `Access advanced shift scheduling`
  String get featureAdvancedScheduling {
    return Intl.message(
      'Access advanced shift scheduling',
      name: 'featureAdvancedScheduling',
      desc: '',
      args: [],
    );
  }

  /// `Mark Attendance`
  String get featureMarkAttendance {
    return Intl.message(
      'Mark Attendance',
      name: 'featureMarkAttendance',
      desc: '',
      args: [],
    );
  }

  /// `Continue Free`
  String get continueFreeButton {
    return Intl.message(
      'Continue Free',
      name: 'continueFreeButton',
      desc: '',
      args: [],
    );
  }

  /// `Go Pro`
  String get goProButton {
    return Intl.message('Go Pro', name: 'goProButton', desc: '', args: []);
  }

  /// `Congratulations!`
  String get Congratulations {
    return Intl.message(
      'Congratulations!',
      name: 'Congratulations',
      desc: '',
      args: [],
    );
  }

  /// `You have now successfully subscribed to Shiftwise Pro.`
  String get Congratulationstext {
    return Intl.message(
      'You have now successfully subscribed to Shiftwise Pro.',
      name: 'Congratulationstext',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get Continue {
    return Intl.message('Continue', name: 'Continue', desc: '', args: []);
  }

  /// `No backup found`
  String get Notfound {
    return Intl.message(
      'No backup found',
      name: 'Notfound',
      desc: '',
      args: [],
    );
  }

  /// `Create a backup of your data to prevent loss.`
  String get backupDescription {
    return Intl.message(
      'Create a backup of your data to prevent loss.',
      name: 'backupDescription',
      desc: '',
      args: [],
    );
  }

  /// `Backup Path`
  String get Backuppath {
    return Intl.message('Backup Path', name: 'Backuppath', desc: '', args: []);
  }

  /// `Backup & Restore`
  String get restoreBackup {
    return Intl.message(
      'Backup & Restore',
      name: 'restoreBackup',
      desc: '',
      args: [],
    );
  }

  /// `Backup created successfully!`
  String get backupSuccess {
    return Intl.message(
      'Backup created successfully!',
      name: 'backupSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Backup failed. Please try again.`
  String get backupFailed {
    return Intl.message(
      'Backup failed. Please try again.',
      name: 'backupFailed',
      desc: '',
      args: [],
    );
  }

  /// `No file selected.`
  String get Notselected {
    return Intl.message(
      'No file selected.',
      name: 'Notselected',
      desc: '',
      args: [],
    );
  }

  /// `Invalid file path.`
  String get Invalidfilepath {
    return Intl.message(
      'Invalid file path.',
      name: 'Invalidfilepath',
      desc: '',
      args: [],
    );
  }

  /// `Backup restored successfully.`
  String get restoreSuccess {
    return Intl.message(
      'Backup restored successfully.',
      name: 'restoreSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to restore backup.`
  String get restoreFailed {
    return Intl.message(
      'Failed to restore backup.',
      name: 'restoreFailed',
      desc: '',
      args: [],
    );
  }

  /// `Restore Data`
  String get restoreData {
    return Intl.message(
      'Restore Data',
      name: 'restoreData',
      desc: '',
      args: [],
    );
  }

  /// `Annually`
  String get Annually {
    return Intl.message('Annually', name: 'Annually', desc: '', args: []);
  }

  /// `Select a subscription plan that suits your needs.`
  String get subscriptionSubtitle {
    return Intl.message(
      'Select a subscription plan that suits your needs.',
      name: 'subscriptionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get monthly {
    return Intl.message('Monthly', name: 'monthly', desc: '', args: []);
  }

  /// `Google Play services not available`
  String get service {
    return Intl.message(
      'Google Play services not available',
      name: 'service',
      desc: '',
      args: [],
    );
  }

  /// `Shiftwise Pro`
  String get ShiftwisePro {
    return Intl.message(
      'Shiftwise Pro',
      name: 'ShiftwisePro',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited Employee Access`
  String get featureUnlimitedEmployeesTitle {
    return Intl.message(
      'Unlimited Employee Access',
      name: 'featureUnlimitedEmployeesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add more than 5 employees to your team with a paid plan`
  String get featureUnlimitedEmployeesSubtitle {
    return Intl.message(
      'Add more than 5 employees to your team with a paid plan',
      name: 'featureUnlimitedEmployeesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Auto Backup`
  String get featureAutoBackupTitle {
    return Intl.message(
      'Auto Backup',
      name: 'featureAutoBackupTitle',
      desc: '',
      args: [],
    );
  }

  /// `Keep your data safe with automatic backup feature`
  String get featureAutoBackupSubtitle {
    return Intl.message(
      'Keep your data safe with automatic backup feature',
      name: 'featureAutoBackupSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Advanced Shift Scheduling`
  String get featureAdvancedSchedulingTitle {
    return Intl.message(
      'Advanced Shift Scheduling',
      name: 'featureAdvancedSchedulingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create shifts for the upcoming weeks in advance.`
  String get featureAdvancedSchedulingSubtitle {
    return Intl.message(
      'Create shifts for the upcoming weeks in advance.',
      name: 'featureAdvancedSchedulingSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Mark Attendance`
  String get featureMarkAttendanceTitle {
    return Intl.message(
      'Mark Attendance',
      name: 'featureMarkAttendanceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Keep track of daily attendance of your team.`
  String get featureMarkAttendanceSubtitle {
    return Intl.message(
      'Keep track of daily attendance of your team.',
      name: 'featureMarkAttendanceSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Write Feedback`
  String get feedback {
    return Intl.message('Write Feedback', name: 'feedback', desc: '', args: []);
  }

  /// `Rate Us`
  String get rateUs {
    return Intl.message('Rate Us', name: 'rateUs', desc: '', args: []);
  }

  /// `Share App`
  String get shareApp {
    return Intl.message('Share App', name: 'shareApp', desc: '', args: []);
  }

  /// `No mail app found on this device.`
  String get noMailApp {
    return Intl.message(
      'No mail app found on this device.',
      name: 'noMailApp',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open Gmail app.`
  String get noGmailApp {
    return Intl.message(
      'Failed to open Gmail app.',
      name: 'noGmailApp',
      desc: '',
      args: [],
    );
  }

  /// `Play Store app not found on this device.`
  String get noPlayStoreApp {
    return Intl.message(
      'Play Store app not found on this device.',
      name: 'noPlayStoreApp',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Service`
  String get termsOfService {
    return Intl.message(
      'Terms of Service',
      name: 'termsOfService',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `Version`
  String get version {
    return Intl.message('Version', name: 'version', desc: '', args: []);
  }

  /// `Developed by Linear Apps`
  String get developedBy {
    return Intl.message(
      'Developed by Linear Apps',
      name: 'developedBy',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get contactEmail {
    return Intl.message('Contact', name: 'contactEmail', desc: '', args: []);
  }

  /// `All Employees`
  String get AllEmployees {
    return Intl.message(
      'All Employees',
      name: 'AllEmployees',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open Play Store.`
  String get failplaystore {
    return Intl.message(
      'Failed to open Play Store.',
      name: 'failplaystore',
      desc: '',
      args: [],
    );
  }

  /// `Failed to share the app.`
  String get failshare {
    return Intl.message(
      'Failed to share the app.',
      name: 'failshare',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update {
    return Intl.message('Update', name: 'update', desc: '', args: []);
  }

  /// `Error updating employee:`
  String get errorupdate {
    return Intl.message(
      'Error updating employee:',
      name: 'errorupdate',
      desc: '',
      args: [],
    );
  }

  /// `Employee name already exists`
  String get alredyexist {
    return Intl.message(
      'Employee name already exists',
      name: 'alredyexist',
      desc: '',
      args: [],
    );
  }

  /// `Employee ID already exists`
  String get alredyexistID {
    return Intl.message(
      'Employee ID already exists',
      name: 'alredyexistID',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Employee Name`
  String get empname {
    return Intl.message('Employee Name', name: 'empname', desc: '', args: []);
  }

  /// `Employee ID`
  String get empid {
    return Intl.message('Employee ID', name: 'empid', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Shift Details`
  String get shiftDetails {
    return Intl.message(
      'Shift Details',
      name: 'shiftDetails',
      desc: '',
      args: [],
    );
  }

  /// `Monday`
  String get monday {
    return Intl.message('Monday', name: 'monday', desc: '', args: []);
  }

  /// `Tuesday`
  String get tuesday {
    return Intl.message('Tuesday', name: 'tuesday', desc: '', args: []);
  }

  /// `Wednesday`
  String get wednesday {
    return Intl.message('Wednesday', name: 'wednesday', desc: '', args: []);
  }

  /// `Thursday`
  String get thursday {
    return Intl.message('Thursday', name: 'thursday', desc: '', args: []);
  }

  /// `Friday`
  String get friday {
    return Intl.message('Friday', name: 'friday', desc: '', args: []);
  }

  /// `Saturday`
  String get saturday {
    return Intl.message('Saturday', name: 'saturday', desc: '', args: []);
  }

  /// `Sunday`
  String get sunday {
    return Intl.message('Sunday', name: 'sunday', desc: '', args: []);
  }

  /// `Employee Shift for`
  String get shareImgtext {
    return Intl.message(
      'Employee Shift for',
      name: 'shareImgtext',
      desc: '',
      args: [],
    );
  }

  /// `Shift`
  String get shift {
    return Intl.message('Shift', name: 'shift', desc: '', args: []);
  }

  /// `employee_shift_shared`
  String get shiftshare {
    return Intl.message(
      'employee_shift_shared',
      name: 'shiftshare',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get img {
    return Intl.message('Image', name: 'img', desc: '', args: []);
  }

  /// `PDF`
  String get pdf {
    return Intl.message('PDF', name: 'pdf', desc: '', args: []);
  }

  /// `Share Image`
  String get shareimg {
    return Intl.message('Share Image', name: 'shareimg', desc: '', args: []);
  }

  /// `Share PDF`
  String get sharepdf {
    return Intl.message('Share PDF', name: 'sharepdf', desc: '', args: []);
  }

  /// `Date`
  String get Date {
    return Intl.message('Date', name: 'Date', desc: '', args: []);
  }

  /// `Remove Employee`
  String get removeEmployee {
    return Intl.message(
      'Remove Employee',
      name: 'removeEmployee',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to remove`
  String get removeEmployeetext {
    return Intl.message(
      'Are you sure you want to remove',
      name: 'removeEmployeetext',
      desc: '',
      args: [],
    );
  }

  /// `from this week's shift table?`
  String get removeEmployeetext2 {
    return Intl.message(
      'from this week\'s shift table?',
      name: 'removeEmployeetext2',
      desc: '',
      args: [],
    );
  }

  /// `(Employee will remain in your main employee list)`
  String get remains {
    return Intl.message(
      '(Employee will remain in your main employee list)',
      name: 'remains',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `Mon`
  String get mondayAbbrc {
    return Intl.message('Mon', name: 'mondayAbbrc', desc: '', args: []);
  }

  /// `Tue`
  String get tuesdayAbbrc {
    return Intl.message('Tue', name: 'tuesdayAbbrc', desc: '', args: []);
  }

  /// `Wed`
  String get wednesdayAbbrc {
    return Intl.message('Wed', name: 'wednesdayAbbrc', desc: '', args: []);
  }

  /// `Thu`
  String get thursdayAbbrc {
    return Intl.message('Thu', name: 'thursdayAbbrc', desc: '', args: []);
  }

  /// `Fri`
  String get fridayAbbrc {
    return Intl.message('Fri', name: 'fridayAbbrc', desc: '', args: []);
  }

  /// `Sat`
  String get saturdayAbbrc {
    return Intl.message('Sat', name: 'saturdayAbbrc', desc: '', args: []);
  }

  /// `Sun`
  String get sundayAbbrc {
    return Intl.message('Sun', name: 'sundayAbbrc', desc: '', args: []);
  }

  /// `Mon`
  String get mondayAbbr {
    return Intl.message('Mon', name: 'mondayAbbr', desc: '', args: []);
  }

  /// `Tue`
  String get tuesdayAbbr {
    return Intl.message('Tue', name: 'tuesdayAbbr', desc: '', args: []);
  }

  /// `Wed`
  String get wednesdayAbbr {
    return Intl.message('Wed', name: 'wednesdayAbbr', desc: '', args: []);
  }

  /// `Thu`
  String get thursdayAbbr {
    return Intl.message('Thu', name: 'thursdayAbbr', desc: '', args: []);
  }

  /// `Fri`
  String get fridayAbbr {
    return Intl.message('Fri', name: 'fridayAbbr', desc: '', args: []);
  }

  /// `Sat`
  String get saturdayAbbr {
    return Intl.message('Sat', name: 'saturdayAbbr', desc: '', args: []);
  }

  /// `Sun`
  String get sundayAbbr {
    return Intl.message('Sun', name: 'sundayAbbr', desc: '', args: []);
  }

  /// `Add Shift`
  String get addShift {
    return Intl.message('Add Shift', name: 'addShift', desc: '', args: []);
  }

  /// `Start Time`
  String get startTime {
    return Intl.message('Start Time', name: 'startTime', desc: '', args: []);
  }

  /// `End Time`
  String get endTime {
    return Intl.message('End Time', name: 'endTime', desc: '', args: []);
  }

  /// `Shift Name`
  String get shiftname {
    return Intl.message('Shift Name', name: 'shiftname', desc: '', args: []);
  }

  /// `Present`
  String get Present {
    return Intl.message('Present', name: 'Present', desc: '', args: []);
  }

  /// `Absent`
  String get Absent {
    return Intl.message('Absent', name: 'Absent', desc: '', args: []);
  }

  /// `Leave`
  String get Leave {
    return Intl.message('Leave', name: 'Leave', desc: '', args: []);
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `(Attendance can only be marked for today and prior dates.)`
  String get markAttendancelimit {
    return Intl.message(
      '(Attendance can only be marked for today and prior dates.)',
      name: 'markAttendancelimit',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a shift name or time range.`
  String get shiftwarning {
    return Intl.message(
      'Please enter a shift name or time range.',
      name: 'shiftwarning',
      desc: '',
      args: [],
    );
  }

  /// `Your shift tracking will appear here.`
  String get emptytable {
    return Intl.message(
      'Your shift tracking will appear here.',
      name: 'emptytable',
      desc: '',
      args: [],
    );
  }

  /// `Tap below to begin.`
  String get begin {
    return Intl.message(
      'Tap below to begin.',
      name: 'begin',
      desc: '',
      args: [],
    );
  }

  /// `Unlock Advanced Shift Scheduling`
  String get unlock {
    return Intl.message(
      'Unlock Advanced Shift Scheduling',
      name: 'unlock',
      desc: '',
      args: [],
    );
  }

  /// `You can create shifts for the upcoming or previous weeks with the Pro version.`
  String get proversion {
    return Intl.message(
      'You can create shifts for the upcoming or previous weeks with the Pro version.',
      name: 'proversion',
      desc: '',
      args: [],
    );
  }

  /// `Select Employees`
  String get select {
    return Intl.message('Select Employees', name: 'select', desc: '', args: []);
  }

  /// `Add New`
  String get addnew {
    return Intl.message('Add New', name: 'addnew', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
