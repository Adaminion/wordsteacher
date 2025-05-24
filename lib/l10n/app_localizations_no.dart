// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get appTitle => 'Memorly';

  @override
  String get forget => 'Glem';

  @override
  String get edit => 'Rediger';

  @override
  String get test => 'Test';

  @override
  String get cloud => 'Sky';

  @override
  String get drill => 'Øvelse';

  @override
  String get options => 'Alternativer';

  @override
  String get help => 'Hjelp';

  @override
  String get loggedOutSuccessfully => 'Logget ut vellykket';

  @override
  String get mustBeLoggedInToSave =>
      'Du må være logget inn for å lagre et nytt ark.';

  @override
  String get loginRequiredToDelete => 'Pålogging kreves for å slette ark.';

  @override
  String get loginRequiredToRename =>
      'Pålogging kreves for å gi nytt navn til ark.';

  @override
  String get loginRequiredToLoad =>
      'Pålogging kreves for å laste inn dine ark.';

  @override
  String get noEntriesToCopy => 'Ingen oppføringer å kopiere.';

  @override
  String get commasDetectedInEntries => 'Kommaer oppdaget i oppføringer';

  @override
  String get commasDetectedMessage =>
      'Oppføringene dine inneholder kommaer. Hvordan vil du formatere teksten for utklippstavlen?';

  @override
  String get lineByLineFormat => 'Linje for linje (S så A)';

  @override
  String get removeCommasFormat => 'Fjern kommaer (S,A)';

  @override
  String get cancel => 'Avbryt';

  @override
  String get copyOperationCancelled => 'Kopieringsoperasjon avbrutt.';

  @override
  String copiedEntriesToClipboard(int count) {
    return 'Kopierte $count oppføringer til utklippstavlen';
  }

  @override
  String get nothingCopiedToClipboard =>
      'Ingenting ble kopiert til utklippstavlen.';

  @override
  String get unsavedChanges => 'Ulagrede endringer';

  @override
  String get unsavedChangesNewFileMessage =>
      'Du har ulagrede endringer. Fortsetter vil slette dem. Fortsette?';

  @override
  String get no => 'Nei';

  @override
  String get yes => 'Ja';

  @override
  String get memoryClearedMessage => 'Minne tømt. Klar for nye oppføringer.';

  @override
  String get clipboardIsEmpty => 'Utklippstavlen er tom';

  @override
  String get clipboardNoProcessableContent =>
      'Utklippstavlen inneholder ikke behandlingsbart innhold.';

  @override
  String get pasteFromClipboard => 'Lim inn fra utklippstavle';

  @override
  String get pasteReplaceOrAppendMessage =>
      'Vil du erstatte eksisterende oppføringer eller legge til dem?';

  @override
  String get append => 'Legg til';

  @override
  String get replace => 'Erstatt';

  @override
  String get pasteOperationCancelled => 'Innsettingsoperasjon avbrutt.';

  @override
  String get noValidQAPairsFound =>
      'Ingen gyldige S&A-par funnet i utklippstavlen med oppdaget format.';

  @override
  String errorPastingFromClipboard(String error) {
    return 'Feil ved innsetting fra utklippstavle: $error';
  }

  @override
  String get unsavedChangesTestFileMessage =>
      'Du har ulagrede endringer. Generering av testfil vil slette dem. Fortsette?';

  @override
  String get generatedTestEntriesMessage =>
      'Genererte 30 nye testoppføringer. Klikk \"Legg til/Rediger oppføringer\" for å se.';
}
