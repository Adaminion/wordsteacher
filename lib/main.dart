import 'dart:math';
import 'study_screen.dart';
import 'firestore_manager.dart';
//imimport 'package:firebaseim_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'fact_sheets_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
//import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'help_screen.dart';
import 'options_screen.dart';
import 'settings.dart';
//import 'storage_manager.dart';
import 'kiciomodul.dart';
final String wersja = 'Memorly  v. 8.2.0 alpha';

bool showBanner = true;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DateTime expirationDate = DateTime(2025, 6, 1); // June 1, 2025
  final DateTime currentDate = DateTime.now();
   if (currentDate.isAfter(expirationDate)) {
    // Run an expired app version that shows an expiration message
    runApp(const ExpiredApp());
    return;
  }

  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Settings().load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
 @override
Widget build(BuildContext ctx) => MaterialApp(
  title: wersja,
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    primarySwatch: Colors.green,
    // Main background color - a very light lime/yellow
    scaffoldBackgroundColor: const Color(0xFFF7F9D9), 
    // Card and form field colors - slightly different shade for contrast
    cardColor: const Color(0xFFEFF2C0),
    // Input decorations for text fields
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFFEFF2C0),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade600, width: 2),
      ),
    ),
    // Button theme with green colors
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade500,
        foregroundColor: Colors.white,
      ),
    ),
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.green.shade700,
      ),
    ),
    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFD9E5A7),
      foregroundColor: Colors.green.shade900,
      elevation: 0,
    ),
  ),
  home: const memorlyHome(),
);
}


class ExpiredApp extends StatelessWidget {
  const ExpiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memorly - Expired',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF7F9D9),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Memorly - Expired Version'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.red, size: 80),
                SizedBox(height: 20),
                Text(
                  'This version has expired',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'The trial period for this application has ended on June 1, 2025. '
                  'Please contact the developer for information about obtaining a new version.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Maybe open email app or website
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Contact Developer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class memorlyHome extends StatefulWidget {
  const memorlyHome({super.key});
 
  @override
  _memorlyHomeState createState() => _memorlyHomeState();
}

class _memorlyHomeState extends State<memorlyHome> {
   bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;

  TextEditingController newQCtrl = TextEditingController();
  TextEditingController newACtrl = TextEditingController();
  FocusNode questionFocusNode = FocusNode();
  FocusNode answerFocusNode = FocusNode();
  bool saved = true;
  String status = 'Idle';
  int? editingIndex;
  String? currentPath;
  
  // ADD THE initState METHOD RIGHT HERE, between the variable declarations and dispose method
  @override
  void initState() {
    super.initState();
    
    // Add this listener to update UI when auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          // This forces a UI refresh when authentication state changes
        });
      }
    });
  }
  // Make sure to dispose focus nodes when widget is disposed

  // Make sure to dispose focus nodes when widget is disposed
  @override
  void dispose() {
    newQCtrl.dispose();
    newACtrl.dispose();
    questionFocusNode.dispose();
    answerFocusNode.dispose();
    super.dispose();
  }
  @override

    

  Future<String?> _promptFilename() async {
    
                print(entries.length);
                print('tu8e');
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Save As'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Filename'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
  title: Text(wersja),
  actions: [
    StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        final user = snap.data;
        return IconButton(
          icon: user == null
              ? Icon(Icons.person_add, color: Colors.grey, size:32)  //i
              : (user.photoURL != null && user.photoURL!.isNotEmpty
                  ? CircleAvatar(
                      radius: 28, //TU kicius zmienia rozmiar - buylo 16
                      backgroundImage: NetworkImage(user.photoURL!),
                    )
                  : CircleAvatar(
                      radius: 28, //i tu
                      child: Icon(Icons.person),
                    )),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuthScreen()),
            );
          },
        );
      },
    ),
    if (isUserLoggedIn) // This checks if user is logged in
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          setState(() {
            // Refresh the UI
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged out successfully')),
          );
        },
      ),
  ],
),
    body: Column(
      children: [
if (showBanner)
  MaterialBanner(
    padding: EdgeInsets.all(10),
    content: Row(
      children: [
        Icon(
          status == 'Editing' ? Icons.edit :
          status == 'New' ? Icons.add_circle :
          status == 'Idle' ? Icons.pause :
          Icons.info_outline,
          color: Colors.blue.shade700,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Status: $status | Entries: ${entries.length} | ${saved ? 'Saved' : 'Unsaved'}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.blue.shade50,
    leadingPadding: EdgeInsets.zero,
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            showBanner = false;
          });
        },
        child: Text('Dismiss'),
      ),
    ],
  ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memorly', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildFileControls(),
                if (status == 'Editing')
                  ...[
                    SizedBox(height: 16),
                    // Manual entry form now comes first
                    _buildManualEntry(),
                    SizedBox(height: 16),
                    // Word list is placed below the form, and takes remaining space
                    Expanded(child: _buildWordList()),
                  ]
                else
                  ...[
                    SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Image.asset('assets/logo.png'),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
void _showAboutPage() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HelpScreen()),
  );
}


void _showContactForm() {
  final TextEditingController messageController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Contact Developer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a message to the developer:'),
            SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Your message',
                hintText: 'Feedback, suggestions, or questions...',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would send the message
              // This could connect to Firebase, send an email, etc.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Message sent! Thank you for your feedback.')),
              );
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close both dialogs
            },
            child: Text('Send'),
          ),
        ],
      );
    },
  );
}

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

 Widget _buildFileControls() => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ElevatedButton(
      onPressed: () async {
        await _newFile();
        updateStatus('New');
      },
      child: Text('Clear Memory'),
    ),
    ElevatedButton(
      onPressed: () {
        updateStatus('Editing');
      },
      child: Text('Add/Edit Entries'),
    ),
    ElevatedButton(
      onPressed: entries.isEmpty
          ? null
          : () async {
              final prefs = await SharedPreferences.getInstance();
              final numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 0;
              final repeatQuestions = prefs.getBool('repeatQuestions') ?? false;
              List<Map<String, String>> testEntries = List.from(entries);

              if (numberOfQuestions > 0) {
            
                if (repeatQuestions) {
                  testEntries = [];
                  final random = Random();
                  for (int i = 0; i < numberOfQuestions; i++) {
                    testEntries.add(entries[random.nextInt(entries.length)]);
                  }
                } else {
                  testEntries.shuffle();
                  testEntries = testEntries
                      .take(min(numberOfQuestions, testEntries.length))
                      .toList();
                }
              }

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyScreen(
                    entries: testEntries,
                    mode: StudyMode.test,
                  ),
                ),
              );
              setState(() {});
            },
      child: Text('Start Test'),
    ),
    ElevatedButton(
      onPressed: entries.isEmpty
          ? null
          : () async {
              final drillEntries = List<Map<String, String>>.from(entries);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyScreen(
                    entries: drillEntries,
                    mode: StudyMode.drill,
                  ),
                ),
              );
              setState(() {});
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
      ),
      child: Text('Start Drill'),
    ),
    ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OptionsScreen()),
        );
      },
      child: Text('Options'),
    ),
    ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FactSheetsScreen(
              loadSheets: () => FirestoreManager().getAllFactsheets(),
              saveSheet: (name, entries) =>
                  FirestoreManager().saveFactsheet(name, entries),
            ),
          ),
        );
      },
      child: Text('Manage Online Files'),
    ),
    ElevatedButton(
      onPressed: () {
        // TODO: implement extra action
      },
      child: Text('Extra button'),
    ),
    ElevatedButton(
      onPressed: _showAboutPage,
      child: Text('Help/About'),
    ),
  ],
);

      
  Widget _buildManualEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(status == 'Editing' && editingIndex != null ? 'Edit Entry:' : 'Manual Entry:'),
      
      // Question field (now full width)
      TextField(
        controller: newQCtrl,
        focusNode: questionFocusNode,
        decoration: InputDecoration(labelText: 'Question'),
        // Move to answer field when Enter is pressed
        onSubmitted: (_) {
          FocusScope.of(context).requestFocus(answerFocusNode);
        },
      ),
      
      SizedBox(height: 8),
      
      // Answer field (now full width)
      TextField(
        controller: newACtrl,
        focusNode: answerFocusNode,
        decoration: InputDecoration(labelText: 'Answer'),
        // Add entry when Enter is pressed on the answer field
        onSubmitted: (_) {
          if (status == 'Editing' && editingIndex != null) {
            _updateEntry();
          } else {
            _addEntry();
            // Focus back to the question field for the next entry
            FocusScope.of(context).requestFocus(questionFocusNode);
          }
        },
      ),
      
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
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
          SizedBox(width: 32),

          SizedBox(width: 8),
          ElevatedButton(
               onPressed: _copyToClipboard,
      child: Text('Copy to Clipboard'),
          ),

           ElevatedButton(
      onPressed: _pasteFromClipboard,
      child: Text('Paste from Clipboard'),
    ),



        ],
        SizedBox(width: 8),
      ]),
    ],
  );

  Future<void> _copyToClipboard() async {
    final text = entries.map((e) => '${e['q']}\n${e['a']}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${entries.length} entries to clipboard')),
    );
  }

  Widget _buildWordList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Word List:', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text('${entries.length} entries'),
        ],
      ),
      SizedBox(height: 8),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                var entry = entries[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  color: editingIndex == index ? Colors.blue.shade100 : null,
                  child: ListTile(
                    title: Row(
                      children: [
                        Text('${index + 1}. ', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          flex: 1,
                          child: Text(entry['q']!, 
                            overflow: TextOverflow.ellipsis),
                        ),
                        Text(' → ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          flex: 1, 
                          child: Text(entry['a']!,
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    onTap: () => _editEntry(index),
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );

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

  Future<void> _pasteFromClipboard() async {
   try {
  ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
  if (data == null || data.text == null || data.text!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Clipboard is empty')),
    );
    return;
  }

  String text = data.text!;
  List<String> lines = text.split('\n');
  
  // Ask user if they want to append or replace
  bool shouldReplace = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Paste from Clipboard'),
      content: Text('Do you want to replace existing entries or append to them?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Append'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Replace'),
        ),
      ],
    ),
  ) ?? false;

  // Parse lines in question-answer pairs with error handling
  List<Map<String, String>> newEntries = [];
  bool hasErrors = false;
  
  for (int i = 0; i < lines.length; i += 2) {
    // Skip if we don't have enough lines left for a pair
    if (i + 1 >= lines.length) {
      hasErrors = true;
      continue;
    }
    
    String question = lines[i].trim();
    String answer = lines[i + 1].trim();
    
    // Skip empty lines but don't count as error
    if (question.isEmpty || answer.isEmpty) continue;
    
    try {
      newEntries.add({'q': question, 'a': answer});
    } catch (e) {
      // If any specific pair fails to process, continue with others
      hasErrors = true;
      continue;
    }
  }

  if (newEntries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No valid Q&A pairs found in clipboard')),
    );
    return;
  }

  setState(() {
    if (shouldReplace) {
      entries = newEntries;
    } else {
      entries.addAll(newEntries);
    }
    saved = false;
  });

  String message = 'Added ${newEntries.length} entries from clipboard';
               
                print(entries.length);
                print("tu9");
                
  if (hasErrors) {
    message += ' (some lines could not be processed)';
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error pasting from clipboard: $e')),
  );
}
  }
  void _addEntry() {
    if (newQCtrl.text.isEmpty || newACtrl.text.isEmpty) return;
    setState(() {
      entries.add({'q': newQCtrl.text, 'a': newACtrl.text});
          
                print(entries.length);
                print("tu10");
                

      newQCtrl.clear();
      newACtrl.clear();
      saved = false;
      
      // Request focus back to the question field
      FocusScope.of(context).requestFocus(questionFocusNode);
    });
  }

  void _nextEntry() {
    setState(() {
      newQCtrl.clear();
      newACtrl.clear();
      editingIndex = null;
      
      // Focus the question field when clearing for next entry
      FocusScope.of(context).requestFocus(questionFocusNode);
    });
  }

  void _editEntry(int index) {
    setState(() {
      editingIndex = index;
      newQCtrl.text = entries[index]['q']!;
      newACtrl.text = entries[index]['a']!;
      
      // Focus on question field when editing
      FocusScope.of(context).requestFocus(questionFocusNode);
    });
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

  void _generateTestFile() {
    setState(() {
      for (int i = 1; i <= 30; i++) {
        entries.add({
          'q': '$i + $i',
          'a': '${i * 2}',
        });
      }
      saved = false;
      status = 'Editing';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated 30 test entries')),
    );
  }

  void _cancelEdit() {
    setState(() {
      editingIndex = null;
      newQCtrl.clear();
      newACtrl.clear();
      
      // Reset focus to question field when canceling edit
      FocusScope.of(context).requestFocus(questionFocusNode);
    });
  }
}