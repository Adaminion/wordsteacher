import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
 //final _emailController = TextEditingController(text: "a@adaminion.com");
 //final _passwordController = TextEditingController(text: "123456");

  bool _isLogin = true;
  String? _error;

Future<void> _submit() async {
  try {
    if (_isLogin) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pop(); // ← closes this screen
    } else {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _error = _getErrorMessage(e.code));
    }
  }

  String _getErrorMessage(String code) {
    print ("error code: $code");
    switch (code) {
      case 'user-not-found':
        return 'No user found.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'Email in use.';
      case 'invalid-email':
        return 'Invalid email.';
      case 'weak-password':
        return 'Password too weak.';
      default:
        return 'Unexpected error';
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isUserLoggedIn ? 'User Account' : (_isLogin ? 'Sign In' : 'Sign Up'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isUserLoggedIn) ...[
              // Show user info when logged in
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'You are logged in as:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(FirebaseAuth.instance.currentUser?.email ?? 'Unknown user'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('Log Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Only show login fields when not logged in
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: !isUserLoggedIn,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                enabled: !isUserLoggedIn,
              ),
              const SizedBox(height: 12),
              if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: isUserLoggedIn ? null : _submit,
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: isUserLoggedIn ? null : () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Create Account' : 'Have an account? Sign In'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}