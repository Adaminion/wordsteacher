// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Memorly';

  @override
  String get forget => 'Olvidar';

  @override
  String get edit => 'Editar';

  @override
  String get test => 'Prueba';

  @override
  String get cloud => 'Nube';

  @override
  String get drill => 'Práctica';

  @override
  String get options => 'Opciones';

  @override
  String get help => 'Ayuda';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get mustBeLoggedInToSave =>
      'You must be logged in to save a new sheet.';

  @override
  String get loginRequiredToDelete => 'Login required to delete sheets.';

  @override
  String get loginRequiredToRename => 'Login required to rename sheets.';

  @override
  String get loginRequiredToLoad => 'Login required to load your sheets.';

  @override
  String get noEntriesToCopy => 'No entries to copy.';

  @override
  String get commasDetectedInEntries => 'Commas Detected in Entries';

  @override
  String get commasDetectedMessage =>
      'Your entries contain commas. How would you like to format the text for the clipboard?';

  @override
  String get lineByLineFormat => 'Line by Line (Q then A)';

  @override
  String get removeCommasFormat => 'Remove Commas (Q,A)';

  @override
  String get cancel => 'Cancelar';

  @override
  String get copyOperationCancelled => 'Copy operation cancelled.';

  @override
  String copiedEntriesToClipboard(int count) {
    return 'Copied $count entries to clipboard';
  }

  @override
  String get nothingCopiedToClipboard => 'Nothing was copied to clipboard.';

  @override
  String get unsavedChanges => 'Cambios No Guardados';

  @override
  String get unsavedChangesNewFileMessage =>
      'You have unsaved changes. Proceeding will clear them. Continue?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get memoryClearedMessage => 'Memory cleared. Ready for new entries.';

  @override
  String get clipboardIsEmpty => 'Clipboard is empty';

  @override
  String get clipboardNoProcessableContent =>
      'Clipboard contains no processable content.';

  @override
  String get pasteFromClipboard => 'Paste from Clipboard';

  @override
  String get pasteReplaceOrAppendMessage =>
      'Do you want to replace existing entries or append to them?';

  @override
  String get append => 'Append';

  @override
  String get replace => 'Replace';

  @override
  String get pasteOperationCancelled => 'Paste operation cancelled.';

  @override
  String get noValidQAPairsFound =>
      'No valid Q&A pairs found in clipboard using detected format.';

  @override
  String errorPastingFromClipboard(String error) {
    return 'Error pasting from clipboard: $error';
  }

  @override
  String get unsavedChangesTestFileMessage =>
      'You have unsaved changes. Generating a test file will clear them. Proceed?';

  @override
  String get generatedTestEntriesMessage =>
      'Generated 30 new test entries. Click \"Add/Edit Entries\" to view.';
}
