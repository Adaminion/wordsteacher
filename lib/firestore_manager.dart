import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fact_sheets_screen.dart'; // for FactSheet
import 'kiciomodul.dart';
class FirestoreManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Initialize user document if it doesn't exist
  Future<void> initializeUser() async {
    if (_userId == null) return;
    
    final userDoc = _firestore.collection('users').doc(_userId);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      await userDoc.set({
        'displayName': _auth.currentUser?.displayName ?? 'user',
        'email': _auth.currentUser?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Save factsheet to Firestore
  Future<String?> saveFactsheet(String name, List<Map<String, String>> entries) async {
    if (_userId == null) return null;
    
    try {

            print(entries.length);

                      
           print(entries.length);
           print("savinbg");
                


                  // Create reference to the factsheet document
      final docRef = _firestore.collection('factsheets').doc();

      
      // Set the data for the factsheet
      await docRef.set({
        'userId': _userId, // Associate with current user
        'comm': name,
        'dateAdded': FieldValue.serverTimestamp(),
        'dateModified': FieldValue.serverTimestamp(),
        'entryCount': entries.length,
        'entries': entries.map((e) => {
          'q': e['q'] ?? '',
          'a': e['a'] ?? ''
        }).toList(),
      });
      
      return docRef.id;
    } catch (e) {
      print('Error saving factsheet: $e');
      return null;
    }
  }
  
  // Get all factsheets for the current user
 Future<List<FactSheet>> getAllFactsheets() async {
  if (_userId == null) return [];
  final snapshot = await _firestore
      .collection('factsheets')
      .where('userId', isEqualTo: _userId)
      .orderBy('dateModified', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return FactSheet(
      id: doc.id,
      name: data['comm'] ?? 'Unnamed',
      entries: [], // or call getEntriesFromFactsheet(doc.id)
    );
  }).toList();
}
  
  // Get entries from a specific factsheet
  Future<List<Map<String, String>>> getEntriesFromFactsheet(String factsheetId) async {
    try {
      final docSnapshot = await _firestore.collection('factsheets').doc(factsheetId).get();
      
      if (!docSnapshot.exists) return [];
      
      // Check if the factsheet belongs to the current user
      final data = docSnapshot.data()!;
      if (data['userId'] != _userId) {
        // Optional: Check if it's shared before returning empty
        if (!(data['isShared'] == true)) {
          return [];
        }
      }
      
      final List<dynamic> rawEntries = data['entries'] ?? [];
      
      return rawEntries.map<Map<String, String>>((entry) => {
        'q': entry['q'] ?? '',
        'a': entry['a'] ?? ''
      }).toList();
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }
  
  // Delete a factsheet
  Future<bool> deleteFactsheet(String factsheetId) async {
    try {
      // Verify ownership before deletion
      final docSnapshot = await _firestore.collection('factsheets').doc(factsheetId).get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return false;
      }
      
      await _firestore.collection('factsheets').doc(factsheetId).delete();
      return true;
    } catch (e) {
      print('Error deleting factsheet: $e');
      return false;
    }
  }
  
  // Update a factsheet name
  Future<bool> renameFactsheet(String factsheetId, String newName) async {
    try {
      // Verify ownership before updating
      final docSnapshot = await _firestore.collection('factsheets').doc(factsheetId).get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return false;
      }
      
      await _firestore.collection('factsheets').doc(factsheetId).update({
        'comm': newName,
        'dateModified': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error renaming factsheet: $e');
      return false;
    }
  }
  
  // Add new entries to existing factsheet
  Future<bool> addEntriesToFactsheet(String factsheetId, List<Map<String, String>> newEntries) async {
    try {
      // Get the current factsheet
      final docSnapshot = await _firestore.collection('factsheets').doc(factsheetId).get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return false;
      }
      
      // Get current entries
      final data = docSnapshot.data()!;
      final List<dynamic> existingEntries = data['entries'] ?? [];
      
      // Prepare new entries in the correct format
      final formattedNewEntries = newEntries.map((e) => {
        'q': e['q'] ?? '',
        'a': e['a'] ?? ''
      }).toList();
      
      // Combine existing and new entries
      final updatedEntries = [...existingEntries, ...formattedNewEntries];
      
      // Update factsheet
      await _firestore.collection('factsheets').doc(factsheetId).update({
        'entries': updatedEntries,
        'entryCount': updatedEntries.length,
        'dateModified': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error adding entries: $e');
      return false;
    }
  }
  
  // Toggle sharing status of a factsheet
  Future<bool> toggleFactsheetSharing(String factsheetId, bool isShared) async {
    try {
      // Verify ownership before updating
      final docSnapshot = await _firestore.collection('factsheets').doc(factsheetId).get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return false;
      }
      
      await _firestore.collection('factsheets').doc(factsheetId).update({
        'isShared': isShared,
        'dateModified': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling sharing: $e');
      return false;
    }
  }
}