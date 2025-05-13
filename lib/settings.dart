import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final Settings _instance = Settings._internal();
  factory Settings() => _instance;
  Settings._internal();

  int numberOfQuestions = 5;
  bool canRepeat = true;
  bool invertOrder = false;
  bool showComments = true;
  bool disregardCaps = false;
  bool disregardSpaces = false;
  bool disregardPunctuation = false;
  bool disregardDiacritics = false;
  String qLabel = 'Question';
  String aLabel = 'Answer';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 5;
    canRepeat = prefs.getBool('repeatQuestions') ?? true;
    invertOrder = prefs.getBool('invertOrder') ?? false;
    showComments = prefs.getBool('showComments') ?? true;
    disregardCaps = prefs.getBool('disregardCaps') ?? false;
    disregardSpaces = prefs.getBool('disregardSpaces') ?? false;
    disregardPunctuation = prefs.getBool('disregardPunctuation') ?? false;
    disregardDiacritics = prefs.getBool('disregardDiacritics') ?? false;
    qLabel = prefs.getString('qLabel') ?? 'Question';
    aLabel = prefs.getString('aLabel') ?? 'Answer';
  }
}
