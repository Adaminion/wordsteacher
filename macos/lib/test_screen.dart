import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback_generator.dart'; // Import the feedback generator

class TestScreen extends StatefulWidget {
  final List<Map<String, String>> entries;
  
  const TestScreen({super.key, required this.entries});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int currentIndex = 0;
  int correctAnswers = 0;
  TextEditingController answerController = TextEditingController();
  String? feedback;
  bool? isCorrect;
  bool showFeedback = true; // This will be loaded from preferences

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    
    // If you want to shuffle the questions
    if (widget.entries.isNotEmpty) {
      widget.entries.shuffle();
    }
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load the showFeedback preference (renamed from showComments)
      showFeedback = prefs.getBool('showFeedback') ?? true;
    });
  }

  void checkAnswer() {
    if (widget.entries.isEmpty || currentIndex >= widget.entries.length) return;
    
    // Get user answer and correct answer
    String userAnswer = answerController.text.trim();
    String correctAnswer = widget.entries[currentIndex]['a'] ?? '';
    
    // Load preference values - these would normally be loaded from SharedPreferences
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
      // A simple approach to remove diacritics
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
      
      // Generate feedback message if showFeedback is enabled
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
    if (currentIndex < widget.entries.length - 1) {
      setState(() {
        currentIndex++;
        answerController.clear();
        feedback = null;
        isCorrect = null;
      });
    } else {
      // Test is complete
      showResults();
    }
  }
  
  void showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You answered $correctAnswers out of ${widget.entries.length} questions correctly.'),
            Text('Your score: ${(correctAnswers / widget.entries.length * 100).toStringAsFixed(1)}%'),
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
                
                // Shuffle questions again if needed
                widget.entries.shuffle();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocabCoach - test'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Question ${currentIndex + 1}/${widget.entries.length}',
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
                      widget.entries[currentIndex]['q'] ?? '',
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
              decoration: InputDecoration(
                labelText: 'Your Answer',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check_circle),
                  onPressed: isCorrect == null ? checkAnswer : null,
                ),
              ),
              onSubmitted: (_) => isCorrect == null ? checkAnswer() : null,
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
                        'Correct answer: ${widget.entries[currentIndex]['a'] ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            
            Spacer(),
            
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCorrect != null)
                  ElevatedButton(
                    onPressed: nextQuestion,
                    child: Text(
                      currentIndex < widget.entries.length - 1 
                        ? 'Next Question' 
                        : 'Finish Test'
                    ),
                  ),
              ],
            ),
            
            // Progress indicator
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: (currentIndex + 1) / widget.entries.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}