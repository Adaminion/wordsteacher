import 'package:flutter/material.dart';
import 'settings.dart'; // Ensure this path is correct

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  // Reference to the Settings singleton
  final Settings _settings = Settings();

  // Text controllers for custom labels
  late TextEditingController _questionLabelController;
  late TextEditingController _answerLabelController;
  // Controller for number of questions (from existing code)
  late TextEditingController _numberOfQuestionsController;


  // Options for new dropdowns
  final List<String> _uiLanguages = ['English', 'Polski'];
  final List<String> _gradingSystems = ['A-F', '6-1'];

  @override
  void initState() {
    super.initState();
    _questionLabelController = TextEditingController(text: _settings.questionLabel);
    _answerLabelController = TextEditingController(text: _settings.answerLabel);
    // Initialize controller for numberOfQuestions if it's not already
    _numberOfQuestionsController = TextEditingController(text: _settings.numberOfQuestions.toString());

    // Ensure current settings values are valid for dropdowns, or set to default
    if (!_uiLanguages.contains(_settings.uiLanguage)) {
      _settings.uiLanguage = _uiLanguages[0]; // Default to English
    }
    if (!_gradingSystems.contains(_settings.gradingSystem)) {
      _settings.gradingSystem = _gradingSystems[0]; // Default to A-F
    }
  }

  @override
  void dispose() {
    _questionLabelController.dispose();
    _answerLabelController.dispose();
    _numberOfQuestionsController.dispose(); // Dispose this too
    super.dispose();
  }

  // Helper to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 10.0), // Added more bottom padding
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  // Helper to build dropdowns
  Widget _buildDropdownSetting<T>({
    required String label,
    required T currentValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        ),
        value: currentValue,
        items: items.map((T value) {
          return DropdownMenuItem<T>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (T? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // New Localization & Display Section
          _buildSectionTitle('Localization & Display'),
          _buildDropdownSetting<String>(
            label: 'UI Language',
            currentValue: _settings.uiLanguage,
            items: _uiLanguages,
            onChanged: (String? newValue) {
              setState(() {
                _settings.uiLanguage = newValue!;
              });
            },
          ),
          _buildDropdownSetting<String>(
            label: 'Grading System',
            currentValue: _settings.gradingSystem,
            items: _gradingSystems,
            onChanged: (String? newValue) {
              setState(() {
                _settings.gradingSystem = newValue!;
              });
            },
          ),
          const Divider(height: 32, thickness: 1),

          // Test Settings Section (Moved here)
          _buildSectionTitle('Test Settings'),
          // Number of questions
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            title: const Text('Number of questions'),
            trailing: SizedBox(
              width: 150, // Keep existing layout for this complex widget
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox( // Changed Container to SizedBox for consistency
                    width: 60,
                    child: TextField( // Removed decoration for border, rely on ListTile's structure
                      controller: _numberOfQuestionsController, // Use the initialized controller
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(), // Added a simple border
                      ),
                      onChanged: (value) {
                        setState(() {
                          _settings.numberOfQuestions = int.tryParse(value) ?? 15;
                          if (_settings.numberOfQuestions < 0) _settings.numberOfQuestions = 0;
                           // Update controller if value is sanitized
                          _numberOfQuestionsController.text = _settings.numberOfQuestions.toString();
                          _numberOfQuestionsController.selection = TextSelection.fromPosition(TextPosition(offset: _numberOfQuestionsController.text.length));
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 30, // Adjusted height for better touch target
                        width: 30,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_drop_up, size: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _settings.numberOfQuestions++;
                              _numberOfQuestionsController.text = _settings.numberOfQuestions.toString();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 30, // Adjusted height
                        width: 30,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_drop_down, size: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              if (_settings.numberOfQuestions > 0) _settings.numberOfQuestions--;
                              _numberOfQuestionsController.text = _settings.numberOfQuestions.toString();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CheckboxListTile(
            title: const Text('Questions can repeat'),
            value: _settings.repeatQuestions,
            onChanged: (bool? value) {
              setState(() {
                _settings.repeatQuestions = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Invert asking order'),
            value: _settings.invertAskingOrder,
            onChanged: (bool? value) {
              setState(() {
                _settings.invertAskingOrder = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Show feedback'),
            value: _settings.showFeedback,
            onChanged: (bool? value) {
              setState(() {
                _settings.showFeedback = value ?? true;
              });
            },
          ),
          const Divider(height: 32, thickness: 1),

          // Answer Matching Section
          _buildSectionTitle('Answer Matching'),
          CheckboxListTile(
            title: const Text('Disregard capitalization'),
            value: _settings.ignoreCaps,
            onChanged: (bool? value) {
              setState(() {
                _settings.ignoreCaps = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard spaces'),
            value: _settings.ignoreSpaces,
            onChanged: (bool? value) {
              setState(() {
                _settings.ignoreSpaces = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard punctuation'),
            value: _settings.ignorePunctuation,
            onChanged: (bool? value) {
              setState(() {
                _settings.ignorePunctuation = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard diacritics'),
            value: _settings.ignoreDiacritics,
            onChanged: (bool? value) {
              setState(() {
                _settings.ignoreDiacritics = value ?? true;
              });
            },
          ),
          const Divider(height: 32, thickness: 1),

          // Custom Labels Section
          _buildSectionTitle('Custom Labels'),
          Padding( // Added padding for TextFields
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _questionLabelController,
              decoration: const InputDecoration(
                labelText: 'Question Label',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _settings.questionLabel = value.isEmpty ? 'Question' : value;
                });
              },
            ),
          ),
          Padding( // Added padding for TextFields
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _answerLabelController,
              decoration: const InputDecoration(
                labelText: 'Answer Label',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _settings.answerLabel = value.isEmpty ? 'Answer' : value;
                });
              },
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Manually update settings from controllers one last time before saving
                  _settings.numberOfQuestions = int.tryParse(_numberOfQuestionsController.text) ?? _settings.numberOfQuestions;
                  _settings.questionLabel = _questionLabelController.text.isEmpty ? 'Question' : _questionLabelController.text;
                  _settings.answerLabel = _answerLabelController.text.isEmpty ? 'Answer' : _answerLabelController.text;

                  await _settings.save(); // Assuming Settings().save() exists and works
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  }
                },
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                   // Manually update settings from controllers one last time before saving
                  _settings.numberOfQuestions = int.tryParse(_numberOfQuestionsController.text) ?? _settings.numberOfQuestions;
                  _settings.questionLabel = _questionLabelController.text.isEmpty ? 'Question' : _questionLabelController.text;
                  _settings.answerLabel = _answerLabelController.text.isEmpty ? 'Answer' : _answerLabelController.text;

                  await _settings.saveAsDefault(); // Assuming Settings().saveAsDefault() exists
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved as default')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Use Theme.of(context).colorScheme.primary for theming
                ),
                child: const Text('Save as default'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}