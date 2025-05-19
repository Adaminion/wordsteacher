import 'grade_screen.dart';
import 'dart:io';
import 'settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'feedback_generator.dart';
import 'kiciomodul.dart';

enum StudyMode {
  test,   // Standard test with all questions 
  drill   // Removes correct answers and repeats incorrect ones
}

class StudyScreen extends StatefulWidget {
  final List<Map<String, String>> entries;
  final StudyMode mode;
  
  const StudyScreen({
    super.key, 
    required this.entries,
    required this.mode,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  // Core variables for both modes
  List<Map<String, String>> activeEntries = [];
  int currentIndex = 0;
  int correctAnswers = 0;
  int initialCount = 0;
  TextEditingController answerController = TextEditingController();
  String? feedback;
  bool showFeedback = true;
  bool isCorrect = false;
  String lastUserAnswer = '';
    List<Map<String, dynamic>> testResultsLog = [];
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    
    // Create a copy of the entries to work with
    activeEntries = List.from(widget.entries);
    initialCount = activeEntries.length;
    
    // Shuffle the entries at the start
    if (activeEntries.isNotEmpty) {
      activeEntries.shuffle();
    }

     if (widget.mode == StudyMode.test) {
    testResultsLog.clear(); // Clear log for a new test session
  }


  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showFeedback = prefs.getBool('showFeedback') ?? true;
    });
  }

 void checkAnswer() {
  if (activeEntries.isEmpty || currentIndex >= activeEntries.length) return;
  
  // Get user answer and correct answer
  String userAnswer = answerController.text.trim();
  String correctAnswer = activeEntries[currentIndex]['a'] ?? '';
  
  // Save the original answers for display
  String displayUserAnswer = userAnswer;
  String displayCorrectAnswer = correctAnswer;
  
  // Access the Settings singleton
  final settings = Settings();
  
  if (settings.ignoreCaps) {
    userAnswer = userAnswer.toLowerCase();
    correctAnswer = correctAnswer.toLowerCase();
  }
  
  if (settings.ignoreSpaces) {
    userAnswer = userAnswer.replaceAll(' ', '');
    correctAnswer = correctAnswer.replaceAll(' ', '');
  }
  
  if (settings.ignoreDiacritics) {
    userAnswer = settings.removeDiacritics(userAnswer);
    correctAnswer = settings.removeDiacritics(correctAnswer);
  }
  
  if (settings.ignorePunctuation) {
    userAnswer = userAnswer.replaceAll(RegExp(r'[^\w\s]'), '');
    correctAnswer = correctAnswer.replaceAll(RegExp(r'[^\w\s]'), '');
  }
  
  bool determinedIsCorrect = userAnswer == correctAnswer; // Renamed to avoid conflict

  setState(() {
    isCorrect = determinedIsCorrect; // Update state variable 'isCorrect'
    lastUserAnswer = displayUserAnswer; 
    answerController.text = displayCorrectAnswer; // Show correct answer in field

    if (showFeedback) {
      feedback = determinedIsCorrect 
        ? FeedbackGenerator.getPositiveFeedback() 
        : FeedbackGenerator.getNegativeFeedback();
    } else {
      feedback = determinedIsCorrect ? "Correct" : "Incorrect";
    }

    if (determinedIsCorrect) {
      correctAnswers++;
    }

    // Log results for GradeScreen if in test mode
    if (widget.mode == StudyMode.test) {
      testResultsLog.add({
        'question': activeEntries[currentIndex]['q'] ?? 'N/A', // Original question
        'userAnswer': displayUserAnswer,                    // User's typed answer
        'correctAnswer': displayCorrectAnswer,              // Actual correct answer
        'isCorrect': determinedIsCorrect,                   // Boolean status
      });
    }
  });
}
  
  void nextQuestion() {
    // Different behavior based on mode
    if (widget.mode == StudyMode.drill && isCorrect == true) {
      // DRILL MODE: Remove correct answers from the list
      activeEntries.removeAt(currentIndex);
      
      // If all entries are gone, show completion dialog
      if (activeEntries.isEmpty) {
        showCompletionDialog();
        return;
      }
      
      // Adjust currentIndex if needed
      if (currentIndex >= activeEntries.length) {
        currentIndex = 0;
      }
    } else if (widget.mode == StudyMode.test) {
      // TEST MODE: Just move to the next question
      if (currentIndex < activeEntries.length - 1) {
        currentIndex++;
      } else {
        // Test is complete
        showResults();
        return;
      }
    } else {
      // DRILL MODE with incorrect answer: Move to next or back to beginning
      if (currentIndex < activeEntries.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
        // Optionally reshuffle for drill mode
        if (widget.mode == StudyMode.drill) {
          activeEntries.shuffle();
        }
      }
    }
    
    // Reset for next question
    setState(() {
      answerController.clear();
      feedback = null;
      isCorrect = false;
      lastUserAnswer = ""; // Reset the user's last answer
    });
  }

  void _resetTestState() {
  setState(() {
    currentIndex = 0;
    correctAnswers = 0;
    answerController.clear();
    feedback = null;
    isCorrect = false;
    lastUserAnswer = '';

    if (widget.mode == StudyMode.test) {
      testResultsLog.clear(); // Important: clear the log
    }

    // Re-initialize questions from the original widget entries
    activeEntries = List.from(widget.entries); 
    if (activeEntries.isNotEmpty) {
      activeEntries.shuffle();
    }
    // initialCount is typically set from widget.entries.length in initState
    // If widget.entries can change, initialCount might need updating here too.
    // For simplicity, assuming initialCount set in initState is sufficient for the session.
    initialCount = activeEntries.length; 
  });
}


  

void showResults() {
  // This function is called when a test (StudyMode.test) is complete.
  // Ensure testResultsLog has been populated correctly.

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GradeScreen(
        good: correctAnswers,    // Number of correct answers
        total: initialCount,     // Total number of questions
        results: testResultsLog, // The detailed log of answers
      ),
    ),
  ).then((_) {
    // This block executes when GradeScreen is popped (e.g., its "Back to Main" button is pressed).
    // Now, you can offer the user options: e.g., "Try Again" or "Done".
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (ctxDialog) => AlertDialog( // Use a different context name e.g., ctxDialog
        title: const Text("Test Finished"),
        content: const Text("What would you like to do next?"),
        actions: [
          TextButton(
            child: const Text("Try Again"),
            onPressed: () {
              Navigator.of(ctxDialog).pop(); // Pop this decision dialog
              _resetTestState();           // Reset StudyScreen for another attempt
            },
          ),
          TextButton(
            child: const Text("Done"),
            onPressed: () {
              Navigator.of(ctxDialog).pop();   // Pop this decision dialog
              Navigator.of(context).pop(); // Pop StudyScreen itself to go to the previous screen
            },
          ),
        ],
      ),
    );
  });
}


 void showCompletionDialog() {
  // For Drill mode: Show completion message
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Drill Completed!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Congratulations! You\'ve mastered all $initialCount items.'),
          SizedBox(height: 16),
          Text('Total answers needed: $correctAnswers'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop(); // Return to previous screen
          },
          child: const Text('Done'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            // Reset the drill
            setState(() {
              activeEntries = List.from(widget.entries);
              initialCount = activeEntries.length;
              currentIndex = 0;
              correctAnswers = 0;
              answerController.clear();
              feedback = null;
              isCorrect = false;
              lastUserAnswer = ""; // Reset user's answer
              
              // Shuffle questions again
              activeEntries.shuffle();
            });
          },
          child: const Text('Try Again'),
        ),
        // Always show Save button in Drill mode
        if (widget.mode == StudyMode.drill)
          TextButton(
            onPressed: () {
              _saveRemainingItems();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Save Progress'),
          ),
      ],
    ),
  );
}
  
 Future<void> _saveRemainingItems() async {
  // For Drill mode: Save current remaining items to file
  final filename = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('Save Remaining Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Save remaining ${activeEntries.length} items as:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Filename'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  
  if (filename != null && filename.isNotEmpty) {
    try {
      // Convert the ACTIVE entries to text format (these are the remaining ones)
      final content = activeEntries.map((e) => '${e['q']}|${e['a']}').join('\n');
      
      // Get app's document directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      
      // Write to file
      await file.writeAsString(content);
      
      // If user is logged in, also save to Firebase
      if (FirebaseAuth.instance.currentUser != null) {
        final ref = FirebaseStorage.instance
            .ref('${FirebaseAuth.instance.currentUser!.uid}/$filename');
        await ref.putFile(file);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved: $filename")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving file: $e")),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
  if (activeEntries.isEmpty) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode == StudyMode.test ? 'Test' : 'Drill')),
      body: const Center(child: Text('No questions available')),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('VocabCoach - ${widget.mode == StudyMode.test ? 'Test' : 'Drill'}'),
      actions: [
        // Add Save Progress button (only in drill mode and when progress has been made)
        if (widget.mode == StudyMode.drill && activeEntries.length < initialCount)
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save Progress',
            onPressed: () {
              _saveRemainingItems();
            },
          ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: widget.mode == StudyMode.test 
              ? Text(
                'Question ${currentIndex + 1}/${activeEntries.length}${currentIndex > 0 
                  ? ' - ${(correctAnswers / currentIndex * 100).toStringAsFixed(0)}% correct' 
                  : ''}',
                style: TextStyle(fontSize: 16),
              )
              : Text(
                'Remaining: ${activeEntries.length}/$initialCount',
                style: TextStyle(fontSize: 16),
              ),
          ),
        ),
        // Quit button
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            // Confirm before quitting
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Quit ${widget.mode == StudyMode.test ? 'Test' : 'Drill'}?'),
                content: Text('Progress will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: Text('Quit'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      activeEntries[currentIndex]['q'] ?? '',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Answer input
      TextField(
  controller: answerController,
  enabled: feedback == null, // Use feedback instead to determine if answer has been checked
  decoration: InputDecoration(
    labelText: 'Your Answer',
    border: OutlineInputBorder(),
    filled: feedback != null, // Use feedback to determine if answer has been checked
    fillColor: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
  ),
  onChanged: (_) => setState(() {}),
  onSubmitted: (_) {
    if (feedback == null) {
      checkAnswer();
    } else {
      nextQuestion();
    }
  },
),

            SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
          onPressed: () {
    if (feedback == null) {
      // Answer hasn't been checked yet
      if (answerController.text.isEmpty) {
        answerController.text = "I don't know";
      }
      checkAnswer();
    } else {
      // Answer has been checked, move to next question
      nextQuestion();
    }
  },
  child: Text(
    feedback == null
      ? (answerController.text.isEmpty ? 'No Idea' : 'Check Answer')
      : (widget.mode == StudyMode.test && currentIndex >= activeEntries.length - 1
          ? 'Finish Test' 
          : 'Next Question'),
    style: TextStyle(fontSize: 18),
  ),
),
            ),
            
            SizedBox(height: 16),
            
            // Feedback area
            if (feedback != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect == true ? Colors.green.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      isCorrect == true ? 'Correct!' : 'Incorrect',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCorrect == true ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    if (showFeedback) ...[
                      SizedBox(height: 8),
                      Text(
                        feedback!,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    if (isCorrect == false) ...[
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Your answer:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        lastUserAnswer,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            Spacer(),
            
            // Progress indicator
            SizedBox(height: 16),
            widget.mode == StudyMode.test
              ? LinearProgressIndicator(
                  value: (currentIndex + 1) / initialCount,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                )
              : Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (initialCount - activeEntries.length) / initialCount,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('${initialCount - activeEntries.length}/$initialCount mastered'),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}