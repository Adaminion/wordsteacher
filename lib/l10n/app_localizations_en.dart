// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Memorly';

  @override
  String get questionAndAnswerCannotBeEmpty =>
      'Question and answer cannot be empty';

  @override
  String get deleteEntryTitle => 'Delete Entry';

  @override
  String deleteEntryConfirm(Object question) {
    return 'Are you sure you want to delete this entry?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get discardChangesMessage =>
      'Are you sure you want to discard your changes?';

  @override
  String get stay => 'Stay';

  @override
  String get discardAndGoBack => 'Discard and Go Back';
}
