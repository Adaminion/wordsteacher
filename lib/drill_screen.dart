import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'feedback_generator.dart';

class DrillScreen extends StatefulWidget {
  final List<Map<String, String>> entries;
  
  const DrillScreen({super.key, required this.entries});

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  // This will hold our active entries for the drill
  List<Map<String, String>> remainingEntries = [];
  int currentIndex = 0;
  int initialCount = 0;
  int correctAnswers = 0;
  TextEditingController answerController = TextEditingController();
  String? feedback;
  bool? isCorrect;
  bool showFeedback = true;
 bool isTestInProgress = false;
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    
    // Create a copy of the original entries
    remainingEntries = List.from(widget.entries);
    initialCount = remainingEntries.length;
    
    // Shuffle the entries at the start
    if (remainingEntries.isNotEmpty) {
      remainingEntries.shuffle();
    }
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showFeedback = prefs.getBool('showFeedback') ?? true;
    });
  }

  void checkAnswer() {
    if (remainingEntries.isEmpty || currentIndex >= remainingEntries.length) return;
    
    // Get user answer and correct answer
    String userAnswer = answerController.text.trim();
    String correctAnswer = remainingEntries[currentIndex]['a'] ?? '';
    //
    // Store original user answer and correct answer for display
    //String originalUserAnswer = userAnswer;
    //String displayCorrectAnswer = correctAnswer;
    
    // Load preference values
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
      
      // Keep the user's original answer in the input field - we'll show the correct answer elsewhere
      // answerController.text = originalUserAnswer; // This is already the case, so no need to set
      
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
    // Key Drill Feature: Remove correct answers from the list
    if (isCorrect == true) {
      // Remove the current entry from remainingEntries
      remainingEntries.removeAt(currentIndex);
      
      // If all entries are gone, show completion dialog
      if (remainingEntries.isEmpty) {
        showCompletionDialog();
        return;
      }
      
      // Adjust currentIndex if needed
      if (currentIndex >= remainingEntries.length) {
        currentIndex = 0;
      }
    } else {
      // For incorrect answers, move to next item or loop back to start
      if (currentIndex < remainingEntries.length - 1) {
        currentIndex++;
      } else {
        // Reached the end, start from beginning
        currentIndex = 0;
        // Optionally reshuffle remaining items
        remainingEntries.shuffle();
      }
    }
    
    setState(() {
      answerController.clear(); // Clear the answer field for the next question
      feedback = null;
      isCorrect = null;
    });
  }
  
  void showCompletionDialog() {
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
                // Reset with original entries
                remainingEntries = List.from(widget.entries);
                initialCount = remainingEntries.length;
                currentIndex = 0;
                correctAnswers = 0;
                answerController.clear();
                feedback = null;
                isCorrect = null;
                
                // Shuffle questions again
                remainingEntries.shuffle();
              });
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              // This will save the remaining items for future study
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
    final filename = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Save Remaining Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save ${remainingEntries.length} items as:'),
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
        final content = remainingEntries.map((e) => '${e['q']}|${e['a']}').join('\n');
        
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
    if (remainingEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Drill')),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocabCoach - Drill'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Remaining: ${remainingEntries.length}/$initialCount',
                style: TextStyle(fontSize: 16),
              ),
            ),
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
                      remainingEntries[currentIndex]['q'] ?? '',
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
                fillColor: isCorrect == true ? Colors.green.shade50 : Colors.green.shade50, // Green or red based on correctness
                helperText: isCorrect == false ? "Your answer" : null, // Label for the user's answer
                helperStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
                      : 'Next Question',
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
                  color: isCorrect == true ? Colors.green.shade100 : Colors.red.shade100,
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
                      SizedBox(height: 8),
                      Text(
                        'Correct answer: ${remainingEntries[currentIndex]['a'] ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            
            Spacer(),
            
            // Progress indicator
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (initialCount - remainingEntries.length) / initialCount,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                SizedBox(width: 8),
                Text('${initialCount - remainingEntries.length}/$initialCount mastered'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}