import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => MaterialApp(
        title: 'VocabCoach',
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

  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(title: Text('VocabCoach')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VocabCoach', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              if (!inTest) ...[
                _buildFileControls(),
                SizedBox(height: 16),
                _buildManualEntry(),
                SizedBox(height: 24),
                _buildStartTestButton(),
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
              ],
            ),
          ),
        ),
      );

  Widget _buildFileControls() {
    return Row(children: [
      ElevatedButton(onPressed: newFile, child: Text('New File')),
      SizedBox(width: 8),
      ElevatedButton(onPressed: appendFile, child: Text('Append File')),
      SizedBox(width: 8),
      ElevatedButton(onPressed: saveFile, child: Text('Save File')),
      SizedBox(width: 8),
      ElevatedButton(onPressed: openFile, child: Text('Open File')),
      SizedBox(width: 8),
      ElevatedButton(onPressed: () {}, child: Text('Options')),
    ]);
  }

  Widget _buildManualEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manual Entry:'),
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
          SizedBox(width: 8),
          ElevatedButton(onPressed: addEntry, child: Text('Add')),
        ]),
      ],
    );
  }

  Widget _buildStartTestButton() => ElevatedButton(onPressed: startTest, child: Text('Start Test'));

  Widget _buildAnswerField() => TextField(
        controller: answerCtrl,
        decoration: InputDecoration(labelText: 'Answer'),
        onSubmitted: (_) => checkAnswer(),
      );

  Widget _buildTestButtons() => Row(children: [
        ElevatedButton(onPressed: checkAnswer, child: Text('Check')),
        SizedBox(width: 8),
        ElevatedButton(onPressed: endTest, child: Text('End')),
      ]);

  void newFile() {
    setState(() {
      entries.clear();
      currentPath = null;
      saved = false;
    });
  }

  Future<void> openFile() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res == null) return;
    currentPath = res.files.single.path;
    var file = File(currentPath!);
    var data = json.decode(await file.readAsString());
    setState(() {
      entries = List<Map<String, String>>.from(data);
      saved = true;
    });
  }

  Future<void> appendFile() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res == null) return;
    var file = File(res.files.single.path!);
    var data = json.decode(await file.readAsString());
    setState(() {
      entries.addAll(List<Map<String, String>>.from(data));
      saved = false;
    });
  }

  Future<void> saveFile() async {
    String? path = currentPath ?? await FilePicker.platform.saveFile(
          dialogTitle: 'Save word list',
          fileName: 'vocabcoach.json',
        );
    if (path == null) return;
    var file = File(path);
    await file.writeAsString(json.encode(entries));
    setState(() {
      currentPath = path;
      saved = true;
    });
  }

  void addEntry() {
    if (newQCtrl.text.isEmpty || newACtrl.text.isEmpty) return;
    setState(() {
      entries.add({'q': newQCtrl.text, 'a': newACtrl.text});
      newQCtrl.clear();
      newACtrl.clear();
      saved = false;
    });
  }

  void startTest() {
    if (entries.isEmpty) return;
    entries.shuffle();
    currentIndex = 0;
    good = total = 0;
    setState(() {
      inTest = true;
      question = entries[currentIndex]['q']!;
    });
  }

  void checkAnswer() {
    var correct = entries[currentIndex]['a']!;
    total++;
    if (answerCtrl.text.trim().toLowerCase() == correct.toLowerCase()) good++;
    currentIndex++;
    answerCtrl.clear();
    if (currentIndex < entries.length) {
      setState(() {
        question = entries[currentIndex]['q']!;
      });
    } else {
      endTest();
    }
  }

  void endTest() {
    setState(() {
      inTest = false;
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Grade'),
        content: Text('Score: $good / $total'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }
}
