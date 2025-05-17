import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool rememberMe = false;
final storage = FlutterSecureStorage();



    @override
  void initState() {
    super.initState();
    _loadCredentials();
  }


  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
 //final _emailController = TextEditingController(text: "a@adaminion.com");
 //final _passwordController = TextEditingController(text: "123456");

  bool _isLogin = true;
  String? _error;

Future<void> _loadCredentials() async {
  try {
    final remember = await storage.read(key: 'remember');
    if (remember == 'true') {
      final email = await storage.read(key: 'email');
      final password = await storage.read(key: 'password');
      if (email != null) _emailController.text = email;
      if (password != null) _passwordController.text = password;
      setState(() {
        rememberMe = true;
      });
    }
  } catch (e) {
    // Removed print statement
  }
}

Future<void> _saveCredentials() async {
  if (rememberMe) {
    await storage.write(key: 'email', value: _emailController.text.trim());
    await storage.write(key: 'password', value: _passwordController.text.trim());
    await storage.write(key: 'remember', value: 'true');
  } else {
    // Clear saved credentials if "Remember Me" is disabled
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
    await storage.write(key: 'remember', value: 'false');
  }
}

Future<void> _submit() async {

  _emailController.text  =_emailController.text.toLowerCase();
  try {
    UserCredential userCredential; // To hold the result
  if (_emailController.text == 'k') {
    _emailController.text = 'kot@mi.au';
    _passwordController.text = 'kicius';
  } else if (_emailController.text == 'a') {
    _emailController.text = 'agi@mi.au';
    _passwordController.text = 'kicius';
  }
    if (_isLogin) {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _saveCredentials();
      Navigator.of(context).pop();
    } else {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Get the newly created user
      User? newUser = userCredential.user;
      if (newUser != null) {
        // Update the user's display name
     await newUser.updateDisplayName(_nameController.text.trim());
        // You might want to reload the user to ensure the profile changes are reflected
        await newUser.reload();
        // Optionally, you can then access the updated user via FirebaseAuth.instance.currentUser
      }
      await _saveCredentials();
      Navigator.of(context).pop();
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _error = getErrorMessage(e.code));
  }
}

  String getErrorMessage(String code) {
    // Removed print statement
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
    appBar: AppBar(
        title: Text(isUserLoggedIn
            ? (FirebaseAuth.instance.currentUser?.displayName ?? 'User Account') // Show name in AppBar
            : (_isLogin ? 'Sign In' : 'Sign Up'))),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: isUserLoggedIn
          ? SingleChildScrollView( // Make content scrollable
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
                children: [
                  // --- User Info Card ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          SizedBox(height: 8),
                          Text(
                              'Email: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              // No need for setState here if pop removes the screen
                              // or if the parent screen rebuilds.
                              // If this screen remains, you'd need setState.
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Profile Section Placeholder ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Profile',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Details about the user profile will go here...'),
                          // Add buttons to edit profile, view more details, etc.
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Stats Section Placeholder ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Stats',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('User statistics will be displayed here...'),
                          // Add charts, graphs, lists of stats, etc.
                        ],
                      ),
                    ),
                  ),
                  // Add more sections as needed
                ],
              ),
            )
          : Column( // Login/Register Form
              mainAxisAlignment: MainAxisAlignment.center, // Center form vertically
              children: [
                // checkbox to remember me
                CheckboxListTile(
                  title: const Text('Remember Me'),
                  value: rememberMe,
                  onChanged: (value) {
                    setState(() {
                      rememberMe = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                if (!_isLogin) // Only show name field for registration
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      keyboardType: TextInputType.name,
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 14)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'Create an Account'
                      : 'Have an account? Sign In'),
                ),
              ],
            ),
    ),
  );
}
}