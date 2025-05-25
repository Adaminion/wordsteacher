import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'firestore_manager.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final _db = FirestoreManager();
  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

    Future<User?> signIn(String email, String pass) async {
  final cred = await firebaseAuth.signInWithEmailAndPassword(
    email: email,
    password: pass
  );
  final user = cred.user;
  if (user!=null) {
    await _db.initializeUser();
  }
  return user;
}

 Future<User?> signUp(String email, String pass, String displayName) async {
    final cred = await firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: pass
    );
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await _db.initializeUser(); 
    }
    return user;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) {
    return firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return firebaseAuth.signOut();
  }
}