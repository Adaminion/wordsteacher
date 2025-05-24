import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_no.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es'),
    Locale('no'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorly'**
  String get appTitle;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloud;

  /// No description provided for @drill.
  ///
  /// In en, this message translates to:
  /// **'Drill'**
  String get drill;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @mustBeLoggedInToSave.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to save a new sheet.'**
  String get mustBeLoggedInToSave;

  /// No description provided for @loginRequiredToDelete.
  ///
  /// In en, this message translates to:
  /// **'Login required to delete sheets.'**
  String get loginRequiredToDelete;

  /// No description provided for @loginRequiredToRename.
  ///
  /// In en, this message translates to:
  /// **'Login required to rename sheets.'**
  String get loginRequiredToRename;

  /// No description provided for @loginRequiredToLoad.
  ///
  /// In en, this message translates to:
  /// **'Login required to load your sheets.'**
  String get loginRequiredToLoad;

  /// No description provided for @noEntriesToCopy.
  ///
  /// In en, this message translates to:
  /// **'No entries to copy.'**
  String get noEntriesToCopy;

  /// No description provided for @commasDetectedInEntries.
  ///
  /// In en, this message translates to:
  /// **'Commas Detected in Entries'**
  String get commasDetectedInEntries;

  /// No description provided for @commasDetectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your entries contain commas. How would you like to format the text for the clipboard?'**
  String get commasDetectedMessage;

  /// No description provided for @lineByLineFormat.
  ///
  /// In en, this message translates to:
  /// **'Line by Line (Q then A)'**
  String get lineByLineFormat;

  /// No description provided for @removeCommasFormat.
  ///
  /// In en, this message translates to:
  /// **'Remove Commas (Q,A)'**
  String get removeCommasFormat;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copyOperationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Copy operation cancelled.'**
  String get copyOperationCancelled;

  /// No description provided for @copiedEntriesToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} entries to clipboard'**
  String copiedEntriesToClipboard(int count);

  /// No description provided for @nothingCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Nothing was copied to clipboard.'**
  String get nothingCopiedToClipboard;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesNewFileMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Proceeding will clear them. Continue?'**
  String get unsavedChangesNewFileMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @memoryClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Memory cleared. Ready for new entries.'**
  String get memoryClearedMessage;

  /// No description provided for @clipboardIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardIsEmpty;

  /// No description provided for @clipboardNoProcessableContent.
  ///
  /// In en, this message translates to:
  /// **'Clipboard contains no processable content.'**
  String get clipboardNoProcessableContent;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @pasteReplaceOrAppendMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to replace existing entries or append to them?'**
  String get pasteReplaceOrAppendMessage;

  /// No description provided for @append.
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get append;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @pasteOperationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Paste operation cancelled.'**
  String get pasteOperationCancelled;

  /// No description provided for @noValidQAPairsFound.
  ///
  /// In en, this message translates to:
  /// **'No valid Q&A pairs found in clipboard using detected format.'**
  String get noValidQAPairsFound;

  /// No description provided for @errorPastingFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error pasting from clipboard: {error}'**
  String errorPastingFromClipboard(String error);

  /// No description provided for @unsavedChangesTestFileMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Generating a test file will clear them. Proceed?'**
  String get unsavedChangesTestFileMessage;

  /// No description provided for @generatedTestEntriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Generated 30 new test entries. Click \"Add/Edit Entries\" to view.'**
  String get generatedTestEntriesMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'no'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'no':
      return AppLocalizationsNo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
