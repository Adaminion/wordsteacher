// language_selector.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelector extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const LanguageSelector({
    super.key,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
static const List<Map<String, String>> languages = [
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  {'code': 'no', 'name': 'Norsk', 'flag': '🇳🇴'},
  {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱'},
  // Add more languages as needed
];

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.currentLocale.languageCode,
      onChanged: (String? newLanguageCode) async {
        if (newLanguageCode != null) {
          await _saveLanguagePreference(newLanguageCode);
          widget.onLanguageChanged(Locale(newLanguageCode));
        }
      },
      items: languages.map<DropdownMenuItem<String>>((language) {
        return DropdownMenuItem<String>(
          value: language['code'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language['flag']!, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(language['name']!),
            ],
          ),
        );
      }).toList(),
      underline: Container(), // Remove default underline
      icon: Icon(Icons.language),
    );
  }
}

// Helper class to manage app-wide locale state
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language') ?? 'en';
    _locale = Locale(savedLanguage);
    notifyListeners();
  }
}