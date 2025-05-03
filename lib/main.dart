import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => MaterialApp(
        title: 'VocabCoach',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: WordTeacherHome(),
      );
}

class WordTeacherHome extends StatefulWidget {
  @override
  _WordTeacherHomeState createState() => _WordTeacherHomeState();
}

class _WordTeacherHomeState extends State<WordTeacherHome> {
  List<Map<String, String>> entries = [];
  String question = '';
  TextEditingController answerCtrl = TextEditingController();
  TextEditingController newQCtrl = TextEditingController();
  TextEditingController newACtrl = TextEditingController();
  int currentIndex = 0;
  int good = 0, total = 0;
  bool inTest = false;
  String? currentPath;
  bool saved = true;
  String status = 'Idle';
  int? editingIndex;

  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(title: Text('ver 1.06')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VocabCoach', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              // File controls always visible when not testing
              if (!inTest) _buildFileControls(),
              SizedBox(height: 16),
              // Show logo in Idle, manual entry in other states
              if (!inTest && status == 'Idle')
                Expanded(
                  child: Center(
                    child: Image.asset('assets/logo.png', height: 200),
                  ),
                ),
              if (!inTest && status != 'Idle') ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildManualEntry(),
                          ],
                        ),
                      ),
                      if (status == 'Editing') ...[
                        SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildWordList(),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
              if (inTest) ...[
                Text(question, style: TextStyle(fontSize: 24)),
                SizedBox(height: 8),
                _buildAnswerField(),
                SizedBox(height: 16),
                _buildTestButtons(),
                SizedBox(height: 16),
                Text('Score: $good / $total'),
              ],
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Words: ${entries.length}'),
                Text(saved ? 'Saved' : 'Unsaved'),
                Text('State: $status'),
              ],
            ),
          ),
        ),
      );

  Widget _buildFileControls() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
             onPressed: () async {
              await _newFile();
            updateStatus('New');
            },
            child: Text('New File'),
          ),
          ElevatedButton(
            onPressed: () {
              _appendFile();
              updateStatus('Appending');
            },
            child: Text('Append File'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveFile();
            },
            child: Text('Save File'),
          ),
          ElevatedButton(
            onPressed: () {
              _openFile();
              updateStatus('Opening');
            },
            child: Text('Open File'),
          ),
          ElevatedButton(
            onPressed: () {
              updateStatus('Editing');
            },
            child: Text('Edit Words'),
          ),
          ElevatedButton(
            onPressed: entries.isEmpty ? null : () {
              _startTest();
              updateStatus('Test');
            },
            child: Text('Start Test'),
          ),
          ElevatedButton(onPressed: () {}, child: Text('Options')),
          ElevatedButton(
            onPressed: () async {
              if (!saved) {
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Unsaved Changes'),
                    content: Text('You have unsaved changes. Close anyway?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
                if (proceed != true) return;
              }
              updateStatus('Idle');
            },
            child: Text('Close'),
          ),
        ],
      );

  Widget _buildManualEntry() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status == 'Editing' && editingIndex != null ? 'Edit Entry:' : 'Manual Entry:'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: newQCtrl,
                decoration: InputDecoration(labelText: 'Question'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: newACtrl,
                decoration: InputDecoration(labelText: 'Answer'),
              ),
            ),
          ]),
          SizedBox(height: 8),
          Row(children: [
            if (status == 'Editing' && editingIndex != null) ...[
              ElevatedButton(
                onPressed: _updateEntry,
                child: Text('Update'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _deleteEntry,
                child: Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _cancelEdit,
                child: Text('Cancel'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _addEntry,
                child: Text('Add'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _nextEntry,
                child: Text('Next'),
              ),
            ],
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await _saveFile();
              },
              child: Text('Save'),
            ),
          ]),
        ],
      );

  Widget _buildWordList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Word List:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                var entry = entries[index];
                return Card(
                  color: editingIndex == index ? Colors.blue.shade100 : null,
                  child: ListTile(
                    title: Text('${index + 1}. ${entry['q']}'),
                    subtitle: Text(entry['a']!),
                    onTap: () => _editEntry(index),
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildAnswerField() => TextField(
        controller: answerCtrl,
        decoration: InputDecoration(labelText: 'Answer'),
        onSubmitted: (_) => _checkAnswer(),
      );

  Widget _buildTestButtons() => Row(children: [
        ElevatedButton(onPressed: () => _checkAnswer(), child: Text('Check')),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: _nextQuestion,
          child: Text('Next'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            await _saveFile();
          },
          child: Text('Save'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            _endTest();
            updateStatus('Idle');
          },
          child: Text('End'),
        ),
      ]);

  void updateStatus(String s) {
    setState(() {
      status = s;
      if (s != 'Editing') {
        editingIndex = null;
        newQCtrl.clear();
        newACtrl.clear();
      }
    });
  }

Future<void> _newFile() async {
  if (!saved) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('Changes are not saved. Proceed anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),  child: Text('Yes')),
        ],
      ),
    );
    if (proceed != true) return;
  }
  setState(() {
    entries.clear();
    currentPath = null;
    saved = false;
    editingIndex = null;
    newQCtrl.clear();
    newACtrl.clear();
    status = 'New';
  });
}

  Future<void> _openFile() async {
    try {
      var res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json']
      );
      if (res == null) return;
      
      currentPath = res.files.single.path;
      var file = File(currentPath!);
      
      if (p.extension(currentPath!).toLowerCase() == '.txt') {
        var lines = await file.readAsLines();
        entries = lines.where((l) => l.contains('|')).map((l) {
          var parts = l.split('|');
          return {'q': parts[0].trim(), 'a': parts[1].trim()};
        }).toList();
      } else {
        var data = json.decode(await file.readAsString());
        entries = List<Map<String, String>>.from(data);
      }
      
      setState(() {
        saved = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${entries.length} words')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  Future<void> _appendFile() async {
    try {
      var res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json']
      );
      if (res == null) return;
      
      var path = res.files.single.path!;
      var file = File(path);
      
      if (p.extension(path).toLowerCase() == '.txt') {
        var lines = await file.readAsLines();
        var more = lines.where((l) => l.contains('|')).map((l) {
          var parts = l.split('|');
          return {'q': parts[0].trim(), 'a': parts[1].trim()};
        }).toList();
        entries.addAll(more);
      } else {
        var data = json.decode(await file.readAsString());
        entries.addAll(List<Map<String, String>>.from(data));
      }
      
      setState(() {
        saved = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appended ${entries.length} total words')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error appending file: $e')),
      );
    }
  }

  Future<void> _saveFile() async {
    try {
      String? path = currentPath;
      
      // If no current path, use platform-specific approach
      if (path == null) {
        // Try to use system file picker for loading a location
        if (Platform.isAndroid || Platform.isIOS) {
          // On mobile, use app documents directory
          final directory = await getApplicationDocumentsDirectory();
          path = p.join(directory.path, 'vocabcoach_${DateTime.now().millisecondsSinceEpoch}.txt');
        } else {
          // On desktop, let user pick a file to "save as"
          var result = await FilePicker.platform.pickFiles(
            dialogTitle: 'Choose save location',
            type: FileType.custom,
            allowedExtensions: ['txt'],
            allowMultiple: false,
          );
          
          if (result != null && result.files.single.path != null) {
            // Use the selected file's directory as the save location
            path = result.files.single.path!;
            // Change the filename to our default
            var directory = p.dirname(path);
            path = p.join(directory, 'vocabcoach_${DateTime.now().millisecondsSinceEpoch}.txt');
          } else {
            // Fallback to downloads directory
            final directory = await getDownloadsDirectory();
            if (directory != null) {
              path = p.join(directory.path, 'vocabcoach_${DateTime.now().millisecondsSinceEpoch}.txt');
            }
          }
        }
      }
      
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to determine save location.')),
        );
        return;
      }
      
      // Ensure the file has .txt extension
      if (!path.endsWith('.txt')) {
        path = '$path.txt';
      }
      
      var file = File(path);
      var content = entries.map((e) => '${e['q']}|${e['a']}').join('\n');
      await file.writeAsString(content);
      
      setState(() {
        currentPath = path;
        saved = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: ${p.basename(path!)}'),
          action: SnackBarAction(
            label: 'Show',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('File Location'),
                  content: SelectableText(path!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  void _addEntry() {
    if (newQCtrl.text.isEmpty || newACtrl.text.isEmpty) return;
    setState(() {
      entries.add({'q': newQCtrl.text, 'a': newACtrl.text});
      newQCtrl.clear();
      newACtrl.clear();
      saved = false;
    });
  }

  void _nextEntry() {
    newQCtrl.clear();
    newACtrl.clear();
    editingIndex = null;
    setState(() {});
  }

  void _editEntry(int index) {
    editingIndex = index;
    newQCtrl.text = entries[index]['q']!;
    newACtrl.text = entries[index]['a']!;
    setState(() {});
  }

  void _updateEntry() {
    if (editingIndex == null || newQCtrl.text.isEmpty || newACtrl.text.isEmpty) return;
    setState(() {
      entries[editingIndex!] = {'q': newQCtrl.text, 'a': newACtrl.text};
      saved = false;
    });
    _cancelEdit();
  }

  void _deleteEntry() {
    if (editingIndex == null) return;
    setState(() {
      entries.removeAt(editingIndex!);
      saved = false;
    });
    _cancelEdit();
  }

  void _cancelEdit() {
    editingIndex = null;
    newQCtrl.clear();
    newACtrl.clear();
    setState(() {});
  }

  void _startTest() {
    if (entries.isEmpty) return;
    entries.shuffle();
    currentIndex = 0;
    good = 0;
    total = 0;
    inTest = true;
    question = entries[currentIndex]['q']!;
    setState(() {});
  }

  void _checkAnswer() {
    var correct = entries[currentIndex]['a']!;
    total++;
    if (answerCtrl.text.trim().toLowerCase() == correct.toLowerCase()) good++;
    _nextQuestion();
  }

  void _nextQuestion() {
    currentIndex++;
    answerCtrl.clear();
    if (currentIndex < entries.length) {
      question = entries[currentIndex]['q']!;
      setState(() {});
    } else {
      _endTest();
    }
  }

  void _endTest() {
    inTest = false;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Grade'),
        content: Text('Score: $good / $total'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
    setState(() {});
  }
}