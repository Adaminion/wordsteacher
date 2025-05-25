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
  String get questionAndAnswerCannotBeEmpty =>
      'Spørsmål og svar kan ikke være tomme.';

  @override
  String get deleteEntryTitle => 'Slette oppføring?';

  @override
  String deleteEntryConfirm(Object question) {
    return 'Er du sikker på at du vil slette oppføringen: \"$question\"?';
  }

  @override
  String get delete => 'Slett';

  @override
  String get discardChangesMessage =>
      'Du har ulagrede endringer. Vil du forkaste dem og gå tilbake?';

  @override
  String get stay => 'Bli';

  @override
  String get discardAndGoBack => 'Forkast og gå tilbake';
}
