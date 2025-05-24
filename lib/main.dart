// © Adaminion 2025 2505231723

import 'dart:math';
import 'study_screen.dart';
import 'firestore_manager.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'fact_sheets_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
//import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
// import 'package:shared_preferences/shared_preferences.dart'; // No longer needed directly here for test settings
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'help_screen.dart';
import 'options_screen.dart';
import 'settings.dart'; // Import your Settings class
import 'entry_editor_screen.dart';

// NEW: Import for internationalization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Full version string, can be used in About/Help screen
final String fullVersionString = 'Memorly v.0.9.3 beta - 2505231723';
// Shortened title for AppBar
final String appTitle = 'Memorly';

// Set to false by default as AppBar will now handle persistent status
bool showBanner = false;

// Access the global Settings instance
final Settings appSettings = Settings();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DateTime expirationDate = DateTime(2025, 6, 1); // June 1, 2025
  final DateTime currentDate = DateTime.now();
  if (currentDate.isAfter(expirationDate)) {
    runApp(const ExpiredApp());
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Load settings at startup
  await appSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext ctx) => MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        
        // NEW: Add localization delegates and supported locales
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('es'), // Spanish
          Locale('pl'), // French
          Locale('no'), // Norwegian
          Locale('zh'), // Chinese
        ],
        
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF7F9D9),
          cardColor: const Color(0xFFEFF2C0),
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
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade500,
    foregroundColor: Colors.white,
  ),
),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade700,
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFD9E5A7),
            foregroundColor: Colors.green.shade900,
            elevation: 0,
          ),
        ),
        home: const MemorlyHome(),
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

class MemorlyHome extends StatefulWidget {
  const MemorlyHome({super.key});

  @override
  _MemorlyHomeState createState() => _MemorlyHomeState();
}

class _MemorlyHomeState extends State<MemorlyHome> {
  List<Map<String, String>> entries = [];
  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;

  bool saved = true;
  String status = 'Idle';
  String? currentSheetName;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          if (user == null) {
            entries.clear();
            status = 'Idle';
            saved = true;
            currentSheetName = null;
          } else {
            status = 'Idle';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _buildAppBarStatusText() {
    String contextName = currentSheetName ?? "In Memory";
    if (status.startsWith("Viewing Global:")) {
      contextName = status.replaceFirst("Viewing Global: ", "");
    } else if (status.startsWith("Loaded:")) {
      contextName = status.replaceFirst("Loaded: ", "");
    } else if (status.startsWith("Editing:") && currentSheetName != null) {
       contextName = currentSheetName!;
    } else if (status == 'New' || entries.isEmpty && currentSheetName == null) {
      contextName = "New Session";
    }
    else if (status == 'Editing' && currentSheetName != null) {
      contextName = currentSheetName!;
    } else if (status == 'Editing' && entries.isNotEmpty) {
      contextName = "Current Session";
    }
    return '$contextName | ${entries.length} entr${entries.length == 1 ? "y" : "ies"} | ${saved ? "Saved" : "Unsaved"}';
  }

  void _updateStatus(String newStatus, {String? sheetName}) {
    setState(() {
      status = newStatus;
      if (sheetName != null) {
        currentSheetName = sheetName;
      } else if (newStatus == 'New' || (newStatus == 'Idle' && entries.isEmpty)) {
        currentSheetName = null;
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    // NEW: Get the AppLocalizations instance
    final localizations = AppLocalizations.of(ctx)!;
    
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              // CHANGED: Use localized app title
              Text(localizations.appTitle),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  _buildAppBarStatusText(),
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (ctx, snap) {
                final user = snap.data;
                return IconButton(
                  icon: user == null
                      ? Icon(Icons.person_add, color: Colors.grey.shade700, size: 32)
                      : (user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(user.photoURL!),
                            )
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.shade700,
                              child: Icon(Icons.person, color: Colors.white, size: 20,),
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
            if (isUserLoggedIn)
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: "Logout",
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    // CHANGED: Use localized text
                    SnackBar(content: Text(localizations.loggedOutSuccessfully)),
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
                      status == 'Editing'
                          ? Icons.edit_note
                          : status == 'New'
                              ? Icons.add_circle
                              : status == 'Idle' || status.startsWith('Loaded') || status.startsWith('Viewing')
                                  ? Icons.pause_circle_outline
                                  : Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Legacy Status: $status | Entries: ${entries.length} | ${saved ? 'Saved' : 'Unsaved'}',
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
                    Text('Memorly    0.9.0 beta', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    SizedBox(height: 16),
                    _buildFileControls(localizations), // Pass localizations
                    SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain, width: MediaQuery.of(context).size.width * 0.6,),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  void _showAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpScreen()),
    );
  }

  // CHANGED: Accept localizations parameter and use localized strings
  Widget _buildFileControls(AppLocalizations localizations) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            onPressed: entries.isEmpty && status != 'New'
                ? null
                : () async {
                    await _newFile();
                  },
            child: Text(localizations.forget), // CHANGED: Use localized text
          ),
          ElevatedButton(
            onPressed: () async {
              String sheetNameToEdit = currentSheetName ?? (entries.isNotEmpty ? "Current Session" : "New Session");
              if (status == 'New' && entries.isEmpty) sheetNameToEdit = "New Session";

              final List<Map<String, String>>? result = await Navigator.push<List<Map<String, String>>>(
                context,
                MaterialPageRoute(
                  builder: (_) => EntryEditorScreen(
                    initialEntries: List<Map<String, String>>.from(entries),
                    sheetName: sheetNameToEdit,
                  ),
                ),
              );

              if (result != null) {
                setState(() {
                  entries = result;
                  saved = false;
                  _updateStatus('Loaded: $sheetNameToEdit', sheetName: sheetNameToEdit);
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Entries updated from editor.')),
                    );
                  }
                });
              } else {
                 _updateStatus(status, sheetName: currentSheetName);
              }
            },
            child: Text(localizations.edit), // CHANGED: Use localized text
          ),
          ElevatedButton(
            onPressed: entries.isEmpty
                ? null
                : () async {
                    // Use settings from the global appSettings instance
                    final int numberOfQuestionsFromSettings = appSettings.numberOfQuestions;
                    final bool repeatQuestionsFromSettings = appSettings.repeatQuestions;
                    
                    List<Map<String, String>> testEntries = List.from(entries);

                    if (entries.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No entries available to start the test.')),
                      );
                      return;
                    }

                    // If numberOfQuestionsFromSettings is 0, use all entries. Otherwise, use the specified number.
                    if (numberOfQuestionsFromSettings > 0 && numberOfQuestionsFromSettings < entries.length) {
                      if (repeatQuestionsFromSettings) {
                        testEntries = [];
                        final random = Random();
                        for (int i = 0; i < numberOfQuestionsFromSettings; i++) {
                          testEntries.add(entries[random.nextInt(entries.length)]);
                        }
                      } else {
                        testEntries.shuffle();
                        testEntries = testEntries.take(numberOfQuestionsFromSettings).toList();
                      }
                    } else {
                      // Use all entries (either numberOfQuestionsFromSettings is 0 or >= entries.length)
                      // If repeatQuestions is true but we are using all entries, shuffling is enough.
                       if (!repeatQuestionsFromSettings) { // Only shuffle if not repeating and using all
                           testEntries.shuffle();
                       }
                       // If repeating and using all, it implies they can see all questions, possibly more than once if count > entries.length
                       // but current logic for numberOfQuestionsFromSettings > 0 handles the count.
                       // If numberOfQuestionsFromSettings is 0, it means all entries, no specific count to repeat up to.
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
                    setState(() {
                       if (currentSheetName != null) {
                         _updateStatus('Loaded: $currentSheetName', sheetName: currentSheetName);
                       } else {
                         _updateStatus(entries.isEmpty ? 'New' : 'Idle');
                       }
                    });
                  },
            child: Text(localizations.test), // CHANGED: Use localized text
          ),
          ElevatedButton(
         
             onPressed: FirebaseAuth.instance.currentUser == null
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FactSheetsScreen(
                    loadUserSheets: () async {
                      if (FirebaseAuth.instance.currentUser == null) return [];
                      return FirestoreManager().getAllFactsheets();
                    },
                    loadGlobalSheets: () => FirestoreManager().getAllGlobalFactsheets(),
                    saveSheet: (name, screenEntries) {
                      if (FirebaseAuth.instance.currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          // CHANGED: Use localized text
                          SnackBar(content: Text(localizations.mustBeLoggedInToSave)),
                        );
                        return Future.value(null);
                      }
                      return FirestoreManager().saveFactsheet(name, entries);
                    },
                    deleteSheet: (sheetId) async {
                      if (FirebaseAuth.instance.currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          // CHANGED: Use localized text
                          SnackBar(content: Text(localizations.loginRequiredToDelete)),
                        );
                        return false;
                      }
                      return FirestoreManager().deleteFactsheet(sheetId);
                    },
                    renameSheet: (sheetId, newName) async {
                      if (FirebaseAuth.instance.currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          // CHANGED: Use localized text
                          SnackBar(content: Text(localizations.loginRequiredToRename)),
                        );
                        return false;
                      }
                      return FirestoreManager().renameFactsheet(sheetId, newName);
                    },
                    openSheetInEditor: (FactSheet sheetToLoad) async {
                      final List<Map<String, String>> sheetEntriesToLoad;
                      if (sheetToLoad.isGlobal) {
                        sheetEntriesToLoad = await FirestoreManager().getEntriesFromGlobalFactsheet(sheetToLoad.id);
                      } else {
                        if (FirebaseAuth.instance.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            // CHANGED: Use localized text
                            SnackBar(content: Text(localizations.loginRequiredToLoad)),
                          );
                          return;
                        }
                        sheetEntriesToLoad = await FirestoreManager().getEntriesFromFactsheet(sheetToLoad.id);
                      }

                      setState(() {
                        entries.clear();
                        entries.addAll(sheetEntriesToLoad);
                        _updateStatus(
                            sheetToLoad.isGlobal ? 'Viewing Global: ${sheetToLoad.name}' : 'Loaded: ${sheetToLoad.name}',
                            sheetName: sheetToLoad.name
                        );
                        saved = true;
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${sheetToLoad.name}" ready with ${sheetEntriesToLoad.length} entries. Click "Add/Edit Entries" to view/modify.')),
                          );
                        }
                      });
                    },
                    areMainEntriesEmpty: entries.isEmpty,
                  ),
                ),
              );
            },
            child: Text(localizations.cloud), // CHANGED: Use localized text
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
                    setState(() {
                       if (currentSheetName != null) {
                         _updateStatus('Loaded: $currentSheetName', sheetName: currentSheetName);
                       } else {
                         _updateStatus(entries.isEmpty ? 'New' : 'Idle');
                       }
                    });
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(localizations.drill), // CHANGED: Use localized text
          ),
          ElevatedButton(
            onPressed: () async { // OptionsScreen might change settings, so reload them or ensure settings are live
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OptionsScreen()),
              );
              // Optionally, force a settings reload if OptionsScreen doesn't update the global instance live
              // await appSettings.load(); // Or ensure OptionsScreen modifies the appSettings instance directly
              setState(() {
                // Rebuild to reflect any potential settings changes if needed by this screen
              });
            },
            child: Text(localizations.options), // CHANGED: Use localized text
          ),
      //    ElevatedButton(
      //      onPressed: () {
      //        _generateTestFile();
      //      },
      //      child: Text('Test file'),
      //    ),
          ElevatedButton(
            onPressed: _showAboutPage,
            child: Text(localizations.help), // CHANGED: Use localized text
          ),
        ],
      );


  Future<void> _copyToClipboard() async {
    final localizations = AppLocalizations.of(context)!;
    
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // CHANGED: Use localized text
          SnackBar(content: Text(localizations.noEntriesToCopy)),
        );
      }
      return;
    }
     bool hasCommasInEntries = false;
    for (var entry in entries) {
      if (entry['q']!.contains(',') || entry['a']!.contains(',')) {
        hasCommasInEntries = true;
        break;
      }
    }

    String textToCopy;

    if (hasCommasInEntries) {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          // CHANGED: Use localized text
          title: Text(localizations.commasDetectedInEntries),
          content: Text(localizations.commasDetectedMessage),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.lineByLineFormat),
              onPressed: () => Navigator.of(ctx).pop('lineByLine'),
            ),
            TextButton(
              child: Text(localizations.removeCommasFormat),
              onPressed: () => Navigator.of(ctx).pop('removeCommas'),
            ),
            TextButton(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.of(ctx).pop('cancel'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // CHANGED: Use localized text
            SnackBar(content: Text(localizations.copyOperationCancelled)),
          );
        }
        return;
      }

      if (choice == 'lineByLine') {
        textToCopy = entries.map((e) => '${e['q']}\n${e['a']}').join('\n\n');
      } else {
        textToCopy = entries.map((e) {
          String question = e['q']!.replaceAll(',', ' ');
          String answer = e['a']!.replaceAll(',', ' ');
          return '$question,$answer';
        }).join('\n');
      }
    } else {
      textToCopy = entries.map((e) => '${e['q']},${e['a']}').join('\n');
    }

    if (textToCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // CHANGED: Use localized text with placeholder
          SnackBar(content: Text(localizations.copiedEntriesToClipboard(entries.length))),
        );
      }
    } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // CHANGED: Use localized text
          SnackBar(content: Text(localizations.nothingCopiedToClipboard)),
        );
    }
  }


  Future<void> _newFile() async {
    final localizations = AppLocalizations.of(context)!;
    
    if (!saved && entries.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          // CHANGED: Use localized text
          title: Text(localizations.unsavedChanges),
          content: Text(localizations.unsavedChangesNewFileMessage),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(localizations.no)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(localizations.yes)),
          ],
        ),
      );
      if (proceed != true) return;
    }
    setState(() {
      entries.clear();
      saved = true;
      _updateStatus('New');
    });
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // CHANGED: Use localized text
          SnackBar(content: Text(localizations.memoryClearedMessage)),
        );
      }
  }

  Future<void> _pasteFromClipboard() async {
    final localizations = AppLocalizations.of(context)!;
    
     try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null || data.text!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // CHANGED: Use localized text
            SnackBar(content: Text(localizations.clipboardIsEmpty)),
          );
        }
        return;
      }

      String text = data.text!;
      List<String> rawLines = text.split('\n');
      List<String> lines = rawLines.map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

      if (lines.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // CHANGED: Use localized text
            SnackBar(content: Text(localizations.clipboardNoProcessableContent)),
          );
        }
        return;
      }

      bool isCommaSeparatedFormat = true;
      if (lines.isNotEmpty) {
        for (String line in lines) {
          int commaCount = ','.allMatches(line).length;
          if (commaCount != 1 || line.startsWith(',') || line.endsWith(',')) {
            isCommaSeparatedFormat = false;
            break;
          }
        }
      } else {
        isCommaSeparatedFormat = false;
      }
      if (lines.length == 1 && !lines[0].contains(',')) {
           isCommaSeparatedFormat = false;
      }

      bool? shouldReplaceNullable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          // CHANGED: Use localized text
          title: Text(localizations.pasteFromClipboard),
          content: Text(localizations.pasteReplaceOrAppendMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(localizations.append),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(localizations.replace),
            ),
             TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(localizations.cancel),
            ),
          ],
        ),
      );

      if (shouldReplaceNullable == null) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                // CHANGED: Use localized text
                SnackBar(content: Text(localizations.pasteOperationCancelled)),
            );
        }
        return;
      }
      bool shouldReplace = shouldReplaceNullable;

      List<Map<String, String>> newEntriesPasted = [];
      bool hasParsingErrors = false;

      if (isCommaSeparatedFormat) {
        for (String line in lines) {
          List<String> parts = line.split(',');
          if (parts.length == 2) {
            String question = parts[0].trim();
            String answer = parts[1].trim();
            if (question.isNotEmpty && answer.isNotEmpty) {
              newEntriesPasted.add({'q': question, 'a': answer});
            } else {
              hasParsingErrors = true;
            }
          } else {
            hasParsingErrors = true;
          }
        }
      } else {
        for (int i = 0; i < lines.length; i += 2) {
          if (i + 1 >= lines.length) {
            hasParsingErrors = true;
            continue;
          }
          String question = lines[i];
          String answer = lines[i + 1];

          if (question.isEmpty || answer.isEmpty) {
              hasParsingErrors = true;
              continue;
          }
          newEntriesPasted.add({'q': question, 'a': answer});
        }
      }

      if (newEntriesPasted.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // CHANGED: Use localized text
            SnackBar(content: Text(localizations.noValidQAPairsFound)),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          if (shouldReplace) {
            entries.clear();
            currentSheetName = null;
          }
          entries.addAll(newEntriesPasted);
          saved = false;
           _updateStatus(
            'Loaded: ${shouldReplace ? "Pasted Content" : currentSheetName ?? "Pasted Content"}',
            sheetName: shouldReplace ? "Pasted Content" : currentSheetName
          );

        });

        String message = '${shouldReplace ? 'Replaced with' : 'Appended'} ${newEntriesPasted.length} entries from clipboard. Click "Add/Edit Entries" to view.';
        if (hasParsingErrors) {
          message += ' (some lines may not have been processed correctly)';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // CHANGED: Use localized text with error
          SnackBar(content: Text(localizations.errorPastingFromClipboard(e.toString()))),
        );
      }
    }
  }

  void _generateTestFile() {
    final localizations = AppLocalizations.of(context)!;
    
    if (!saved && entries.isNotEmpty) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          // CHANGED: Use localized text
          title: Text(localizations.unsavedChanges),
          content: Text(localizations.unsavedChangesTestFileMessage),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(localizations.no)),
            TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                  _performGenerateTestFile();
                },
                child: Text(localizations.yes)),
          ],
        ),
      ).then((proceed) {
        if (proceed != true) return;
      });
    } else {
      _performGenerateTestFile();
    }
  }

  void _performGenerateTestFile() {
    final localizations = AppLocalizations.of(context)!;
    
    setState(() {
      entries.clear();
      for (int i = 1; i <= 30; i++) {
        entries.add({
          'q': '$i + $i',
          'a': '${i * 2}',
        });
      }
      saved = false;
      _updateStatus('Loaded: Test File', sheetName: "Test File");
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // CHANGED: Use localized text
        SnackBar(content: Text(localizations.generatedTestEntriesMessage)),
      );
    }
  }
}