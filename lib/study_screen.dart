import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'feedback_generator.dart';

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
  bool? isCorrect;
  bool showFeedback = true;

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
    
    // Save the original correct answer for display
    String displayCorrectAnswer = correctAnswer;
    
    // Load preference values from SharedPreferences
    bool ignoreCaps = true;
    bool ignoreSpaces = true;
    bool ignoreDiacritics = true;
    bool ignorePunctuation = true;
    
    // Apply answer matching rules
    if (ignoreCaps) {
      userAnswer = userAnswer.toLowerCase();
      correctAnswer = correctAnswer.toLowerCase();
    }
    
    if (ignoreSpaces) {
      userAnswer = userAnswer.replaceAll(RegExp(r'\s+'), '');
      correctAnswer = correctAnswer.replaceAll(RegExp(r'\s+'), '');
    }
    
    if (ignoreDiacritics) {
      userAnswer = userAnswer
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');
      correctAnswer = correctAnswer
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');
    }
    
    if (ignorePunctuation) {
      userAnswer = userAnswer.replaceAll(RegExp(r'[^\w\s]'), '');
      correctAnswer = correctAnswer.replaceAll(RegExp(r'[^\w\s]'), '');
    }
    
    // Check if answer is correct
    bool correct = userAnswer == correctAnswer;
    
    setState(() {
      isCorrect = correct;
      
      // Show the correct answer in the input field
      answerController.text = displayCorrectAnswer;
      
      if (showFeedback) {
        feedback = correct 
          ? FeedbackGenerator.getPositiveFeedback() 
          : FeedbackGenerator.getNegativeFeedback();
      } else {
        feedback = correct ? "Correct" : "Incorrect";
      }
      
      if (correct) {
        correctAnswers++;
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
      isCorrect = null;
    });
  }
  
  void showResults() {
    // For Test mode: Show final score
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You answered $correctAnswers out of $initialCount questions correctly.'),
            Text('Your score: ${(correctAnswers / initialCount * 100).toStringAsFixed(1)}%'),
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
              // Reset the test
              setState(() {
                currentIndex = 0;
                correctAnswers = 0;
                answerController.clear();
                feedback = null;
                isCorrect = null;
                
                // Restore and shuffle questions
                activeEntries = List.from(widget.entries);
                activeEntries.shuffle();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
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
                isCorrect = null;
                
                // Shuffle questions again
                activeEntries.shuffle();
              });
            },
            child: const Text('Try Again'),
          ),
          // Only show Save button in Drill mode when there are items remaining
          if (widget.mode == StudyMode.drill && activeEntries.isNotEmpty)
            TextButton(
              onPressed: () {
                _saveRemainingItems();
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('Save Remaining Items'),
            ),
        ],
      ),
    );
  }
  
  Future<void> _saveRemainingItems() async {
    // For Drill mode: Save remaining items to file
    final filename = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Save Remaining Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save ${activeEntries.length} items as:'),
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
        // Convert entries to text format
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
          // Add Quit button
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
              enabled: isCorrect == null, // Disable input field after checking
              decoration: InputDecoration(
                labelText: 'Your Answer',
                border: OutlineInputBorder(),
                filled: isCorrect != null, // Enable fill only after checking
                fillColor: isCorrect == true ? Colors.green.shade50 : Colors.red.shade50, // Color based on correctness
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (isCorrect == null) {
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
                  if (isCorrect == null) {
                    if (answerController.text.isEmpty) {
                      answerController.text = "I don't know";
                    }
                    checkAnswer();
                  } else {
                    nextQuestion();
                  }
                },
                child: Text(
                  isCorrect == null
                    ? (answerController.text.isEmpty ? 'No Idea' : 'Check Answer')
                    : (widget.mode == StudyMode.test && currentIndex >= activeEntries.length - 1 && isCorrect != null
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
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Correct answer:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        activeEntries[currentIndex]['a'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green.shade800,
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