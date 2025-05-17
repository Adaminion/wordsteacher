import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Save vocabulary list to Firestore
  Future<String?> saveVocabularyList(String name, List<Map<String, String>> entries) async {
    if (_userId == null) return null;
    
    try {
      // Create reference to the file document
      final docRef = _firestore.collection('files').doc();
      
      // Set the data for the vocabulary list
      await docRef.set({
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
      return null;
    }
  }
  
  // Get all vocabulary lists
  Future<List<Map<String, dynamic>>> getAllVocabularyLists() async {
    if (_userId == null) return [];
    
    try {
      final snapshot = await _firestore.collection('files').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['comm'] ?? 'Unnamed',
          'entryCount': data['entryCount'] ?? 0,
          'dateAdded': data['dateAdded'],
          'dateModified': data['dateModified'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get entries from a specific vocabulary list
  Future<List<Map<String, String>>> getEntriesFromList(String listId) async {
    try {
      final docSnapshot = await _firestore.collection('files').doc(listId).get();
      
      if (!docSnapshot.exists) return [];
      
      final data = docSnapshot.data()!;
      final List<dynamic> rawEntries = data['entries'] ?? [];
      
      return rawEntries.map<Map<String, String>>((entry) => {
        'q': entry['q'] ?? '',
        'a': entry['a'] ?? ''
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Delete a vocabulary list
  Future<bool> deleteVocabularyList(String listId) async {
    try {
      await _firestore.collection('files').doc(listId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Update a vocabulary list name
  Future<bool> renameVocabularyList(String listId, String newName) async {
    try {
      await _firestore.collection('files').doc(listId).update({
        'comm': newName,
        'dateModified': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}