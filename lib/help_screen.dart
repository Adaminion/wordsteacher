import 'package:flutter/material.dart';
// Import url_launcher if you want to launch URLs
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & About'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Image.asset('assets/logo.png', height: 120),
            ),
            SizedBox(height: 20),
            
            // App info
            Text(
              'Memorly v0.7.0 alpha',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'A powerful flashcard and memory training application',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            // Help sections
            _buildHelpSection(
              context,
              'Getting Started',
              'Create a new memory set by clicking on "Add/Edit Entries" and entering question-answer pairs. '
              'You can also paste content from the clipboard or load from online storage.',
            ),
            _buildHelpSection(
              context,
              'Study Modes',
              'Test Mode: Challenge yourself with a randomized test of your knowledge.\n\n'
              'Drill Mode: Practice repeatedly with the entries until you master them.',
            ),
            _buildHelpSection(
              context,
              'Online Features',
              'Sign in to save and load your memory sets from the cloud. '
              'Your data syncs across devices when you\'re logged in.',
            ),
            SizedBox(height: 30),
            
            // Contact section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Contact & Support',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Your Name'),
                    SizedBox(height: 5),
                    InkWell(
                      onTap: () {
                        // Launch email app
                        // launchUrl(Uri.parse('mailto:your.email@example.com'));
                      },
                      child: Text(
                        'your.email@example.com',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    InkWell(
                      onTap: () {
                        // Launch website
                        // launchUrl(Uri.parse('https://yourwebsite.com'));
                      },
                      child: Text(
                        'www.yourwebsite.com',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        _showFeedbackForm(context);
                      },
                      child: Text('Send Feedback'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Copyright
            Text(
              '© 2025 Your Name/Company. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, String content) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  void _showFeedbackForm(BuildContext context) {
    final messageController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Your Email (optional)',
                    hintText: 'Where can we reach you?',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Your Message',
                    hintText: 'Feedback, suggestions, or questions...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
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
                // Here you would process the feedback
                // Could be sent to Firebase, email, etc.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Feedback sent! Thank you.')),
                );
                Navigator.of(context).pop();
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }
}