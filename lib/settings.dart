import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final Settings _instance = Settings._internal();
  factory Settings() => _instance;
  Settings._internal();

  // Test Settings
  int numberOfQuestions = 15;
  bool repeatQuestions = true;
  bool invertAskingOrder = false;
  bool showFeedback = true;
  String gradingSystem = 'A-F';
  String uiLanguage = 'English';


  // Answer Matching Settings
  bool ignoreCaps = true;
  bool ignoreSpaces = true;
  bool ignorePunctuation = true;
  bool ignoreDiacritics = true;

  // Custom Labels
  String questionLabel = 'Question';
  String answerLabel = 'Answer';

  // Map of diacritics for conversion
  final Map<String, String> diacriticMap = {
    // Polish
    'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 
    'ś': 's', 'ź': 'z', 'ż': 'z',
    'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N', 'Ó': 'O', 
    'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z',
    
    // Spanish
    'á': 'a', 'é': 'e', 'í': 'i', 'ú': 'u', 'ñ': 'n', 'ü': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ú': 'U', 'Ñ': 'N', 'Ü': 'U',
    
    // Norwegian
    'æ': 'ae', 'ø': 'o', 'å': 'a',
    'Æ': 'AE', 'Ø': 'O', 'Å': 'A'
  };

  // Helper method to remove diacritics
  String removeDiacritics(String str) {
    return str.split('').map((char) => diacriticMap[char] ?? char).join('');
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Test Settings
    numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 15;
    repeatQuestions = prefs.getBool('repeatQuestions') ?? true;
    invertAskingOrder = prefs.getBool('invertAskingOrder') ?? false;
    showFeedback = prefs.getBool('showFeedback') ?? true;
    gradingSystem = prefs.getString('gradingSystem') ?? 'A-F';
    uiLanguage = prefs.getString('uiLanguage') ?? 'English';
    
    // Answer Matching Settings
    ignoreCaps = prefs.getBool('ignoreCaps') ?? true;
    ignoreSpaces = prefs.getBool('ignoreSpaces') ?? true;
    ignorePunctuation = prefs.getBool('ignorePunctuation') ?? true;
    ignoreDiacritics = prefs.getBool('ignoreDiacritics') ?? true;
    
    // Custom Labels
    questionLabel = prefs.getString('questionLabel') ?? 'Question';
    answerLabel = prefs.getString('answerLabel') ?? 'Answer';
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Test Settings
    await prefs.setInt('numberOfQuestions', numberOfQuestions);
    await prefs.setBool('repeatQuestions', repeatQuestions);
    await prefs.setBool('invertAskingOrder', invertAskingOrder);
    await prefs.setBool('showFeedback', showFeedback);  
    await prefs.setString('gradingSystem', gradingSystem);
    await prefs.setString('uiLanguage', uiLanguage);
    // Answer Matching Settings
    await prefs.setBool('ignoreCaps', ignoreCaps);
    await prefs.setBool('ignoreSpaces', ignoreSpaces);
    await prefs.setBool('ignorePunctuation', ignorePunctuation);
    await prefs.setBool('ignoreDiacritics', ignoreDiacritics);
    
    // Custom Labels
    await prefs.setString('questionLabel', questionLabel);
    await prefs.setString('answerLabel', answerLabel);
  }

  Future<void> saveAsDefault() async {
    await save();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('defaultSettingsSaved', true);
  }
}