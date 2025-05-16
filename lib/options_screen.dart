import 'package:flutter/material.dart';
import 'settings.dart';

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
  
  @override
  void initState() {
    super.initState();
    _questionLabelController = TextEditingController(text: _settings.questionLabel);
    _answerLabelController = TextEditingController(text: _settings.answerLabel);
  }
  
  @override
  void dispose() {
    _questionLabelController.dispose();
    _answerLabelController.dispose();
    super.dispose();
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
                      controller: TextEditingController(text: _settings.numberOfQuestions.toString()),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _settings.numberOfQuestions = int.tryParse(value) ?? 15;
                          if (_settings.numberOfQuestions < 0) _settings.numberOfQuestions = 0;
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
                              _settings.numberOfQuestions++;
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
                              if (_settings.numberOfQuestions > 0) _settings.numberOfQuestions--;
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
                _settings.questionLabel = value.isEmpty ? 'Question' : value;
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
                _settings.answerLabel = value.isEmpty ? 'Answer' : value;
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
                  await _settings.save();
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
                  await _settings.saveAsDefault();
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