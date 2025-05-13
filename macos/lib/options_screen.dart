import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  // Answer Matching Settings (defaults to true)
  bool _ignoreCaps = true;
  bool _ignoreSpaces = true;
  bool _ignoreDiacritics = true;
  bool _ignorePunctuation = true;
  
  // Test Settings
  bool _repeatQuestions = true;  // Changed default to true
  int _numberOfQuestions = 15;   // Changed default to 15
  bool _invertAskingOrder = false;
  bool _showFeedback = true;
  
  // Custom Labels
  String _questionLabel = 'Question';
  String _answerLabel = 'Answer';
  
  // Text controllers for custom labels
  final _questionLabelController = TextEditingController();
  final _answerLabelController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  @override
  void dispose() {
    _questionLabelController.dispose();
    _answerLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Answer Matching Settings
      _ignoreCaps = prefs.getBool('ignoreCaps') ?? true;
      _ignoreSpaces = prefs.getBool('ignoreSpaces') ?? true;
      _ignoreDiacritics = prefs.getBool('ignoreDiacritics') ?? true;
      _ignorePunctuation = prefs.getBool('ignorePunctuation') ?? true;
      
      // Test Settings
      _repeatQuestions = prefs.getBool('repeatQuestions') ?? true;
      _numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 15;
      _invertAskingOrder = prefs.getBool('invertAskingOrder') ?? false;
      _showFeedback = prefs.getBool('showFeedback') ?? true;
      
      // Custom Labels
      _questionLabel = prefs.getString('questionLabel') ?? 'Question';
      _answerLabel = prefs.getString('answerLabel') ?? 'Answer';
      
      _questionLabelController.text = _questionLabel;
      _answerLabelController.text = _answerLabel;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Answer Matching Settings
    await prefs.setBool('ignoreCaps', _ignoreCaps);
    await prefs.setBool('ignoreSpaces', _ignoreSpaces);
    await prefs.setBool('ignoreDiacritics', _ignoreDiacritics);
    await prefs.setBool('ignorePunctuation', _ignorePunctuation);
    
    // Test Settings
    await prefs.setBool('repeatQuestions', _repeatQuestions);
    await prefs.setInt('numberOfQuestions', _numberOfQuestions);
    await prefs.setBool('invertAskingOrder', _invertAskingOrder);
    await prefs.setBool('showFeedback', _showFeedback);
    
    // Custom Labels
    await prefs.setString('questionLabel', _questionLabel);
    await prefs.setString('answerLabel', _answerLabel);
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
          // Answer Matching Section
          const Text(
            'Answer Matching',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Disregard capitalization'),
            value: _ignoreCaps,
            onChanged: (bool? value) {
              setState(() {
                _ignoreCaps = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard spaces'),
            value: _ignoreSpaces,
            onChanged: (bool? value) {
              setState(() {
                _ignoreSpaces = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard punctuation'),
            value: _ignorePunctuation,
            onChanged: (bool? value) {
              setState(() {
                _ignorePunctuation = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Disregard diacritics'),
            value: _ignoreDiacritics,
            onChanged: (bool? value) {
              setState(() {
                _ignoreDiacritics = value ?? true;
              });
            },
          ),
          
          const Divider(height: 32),
          
          // Test Settings Section
          const Text(
            'Test Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Number of questions
          ListTile(
            title: const Text('Number of questions'),
            trailing: SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: TextEditingController(text: _numberOfQuestions.toString()),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _numberOfQuestions = int.tryParse(value) ?? 15;
                          if (_numberOfQuestions < 0) _numberOfQuestions = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_drop_up, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _numberOfQuestions++;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              if (_numberOfQuestions > 0) _numberOfQuestions--;
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
            value: _repeatQuestions,
            onChanged: (bool? value) {
              setState(() {
                _repeatQuestions = value ?? true;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('Invert asking order'),
            value: _invertAskingOrder,
            onChanged: (bool? value) {
              setState(() {
                _invertAskingOrder = value ?? false;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('Show feedback'),
            value: _showFeedback,
            onChanged: (bool? value) {
              setState(() {
                _showFeedback = value ?? true;
              });
            },
          ),
          
          const Divider(height: 32),
          
          // Custom Labels Section
          const Text(
            'Custom Labels',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _questionLabelController,
            decoration: const InputDecoration(
              labelText: 'Question Label',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _questionLabel = value.isEmpty ? 'Question' : value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _answerLabelController,
            decoration: const InputDecoration(
              labelText: 'Answer Label',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _answerLabel = value.isEmpty ? 'Answer' : value;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _savePreferences();
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
                  await _savePreferences();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('defaultSettingsSaved', true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved as default')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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