import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fact_sheets_screen.dart'; // for FactSheet model

class FirestoreManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Initialize user document if it doesn't exist
  Future<void> initializeUser() async {
    if (_userId == null) {
      print('InitializeUser: No user logged in.');
      return;
    }
    
    final userDocRef = _firestore.collection('users').doc(_userId);
    final docSnapshot = await userDocRef.get();
    
    if (!docSnapshot.exists) {
      try {
        await userDocRef.set({
          'displayName': _auth.currentUser?.displayName ?? 'User',
          'email': _auth.currentUser?.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          // Add any other default user fields here, e.g.,
          // 'premiumUser': false, 
          // 'premiumUntil': null,
        });
        print('User document initialized for $_userId');
      } catch (e) {
        print('Error initializing user document for $_userId: $e');
      }
    }
  }

  // Helper to get the user's factsheets subcollection reference
  CollectionReference _userFactsheetsCollection() {
    if (_userId == null) {
      // This case should ideally be prevented by checks in calling methods
      throw Exception('User not logged in. Cannot access factsheets collection.');
    }
    return _firestore.collection('users').doc(_userId).collection('factsheets');
  }
  
  // Helper to get a specific factsheet document reference in the user's subcollection
  DocumentReference _userFactsheetDocument(String factsheetId) {
     if (_userId == null) {
      throw Exception('User not logged in. Cannot access factsheet document.');
    }
    return _userFactsheetsCollection().doc(factsheetId);
  }


  // Save factsheet to Firestore in user's subcollection
  Future<String?> saveFactsheet(String name, List<Map<String, String>> entries) async {
    if (_userId == null) {
      print('SaveFactsheet: User not logged in.');
      return null;
    }

    // Ensure user document exists as a prerequisite (optional, but good practice)
    final userDocSnapshot = await _firestore.collection('users').doc(_userId).get();
    if (!userDocSnapshot.exists) {
      print('SaveFactsheet: User document for $_userId does not exist. Attempting to initialize.');
      await initializeUser(); // Attempt to create it
      final refreshedUserDoc = await _firestore.collection('users').doc(_userId).get();
      if (!refreshedUserDoc.exists) {
        print('SaveFactsheet: User document still missing for $_userId. Cannot save factsheet.');
        return 'USER_DOC_MISSING'; // Indicate error
      }
    }
    
    try {
      print('Saving factsheet: "$name" for user: $_userId with ${entries.length} entries');
      
      final docRef = _userFactsheetsCollection().doc(); // New doc in user's subcollection
      
      final formattedEntries = entries.map((e) => {
        'q': e['q'] ?? '',
        'a': e['a'] ?? ''
      }).toList();
      
      await docRef.set({
        // 'userId': _userId, // Optional: Path implies ownership
        'comm': name,
        'dateAdded': FieldValue.serverTimestamp(),
        'dateModified': FieldValue.serverTimestamp(),
        'entryCount': formattedEntries.length,
        'entries': formattedEntries,
        // 'isShared': false, // Default sharing status if you have this field
      });
      
      print('Successfully saved factsheet with ID: ${docRef.id} for user: $_userId');
      return docRef.id;
    } catch (e) {
      print('Error saving factsheet for user $_userId: $e');
      return null;
    }
  }
  
  // Get all factsheets for the current user from their subcollection
  Future<List<FactSheet>> getAllFactsheets() async {
    if (_userId == null) {
      print('GetAllFactsheets: User not logged in.');
      return [];
    }
    
    try {
      print('Fetching factsheets for user: $_userId');
      final snapshot = await _userFactsheetsCollection()
          .orderBy('dateModified', descending: true)
          .get();
      
      print('Fetched ${snapshot.docs.length} factsheets for user: $_userId');
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; // Cast to Map
        return FactSheet(
          id: doc.id,
          name: data['comm'] ?? 'Unnamed',
          entryCount: data['entryCount'] ?? 0,
          entries: [], // Keep empty for summary list; load details on demand
        );
      }).toList();
    } catch (e) {
      print('Error getting factsheets for user $_userId: $e');
      return [];
    }
  }
  
  // Get entries from a specific factsheet in the user's subcollection
  Future<List<Map<String, String>>> getEntriesFromFactsheet(String factsheetId) async {
    if (_userId == null) {
      print('GetEntries: User not logged in.');
      return [];
    }

    try {
      print('Fetching entries for factsheet: $factsheetId for user: $_userId');
      final docSnapshot = await _userFactsheetDocument(factsheetId).get();
      
      if (!docSnapshot.exists) {
        print('Factsheet $factsheetId does not exist for user $_userId.');
        return [];
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>; // Cast to Map
      
      // Ownership is implicitly handled by the path and security rules.
      // If you still have an 'isShared' field for cross-user access:
      // if (data['isShared'] != true && someOtherConditionIfNotOwner) {
      //   print('Access denied or factsheet not shared.');
      //   return [];
      // }
      
      final List<dynamic> rawEntries = data['entries'] ?? [];
      print('Fetched ${rawEntries.length} entries for factsheet $factsheetId');
      
      return rawEntries.map<Map<String, String>>((entry) {
        // Ensure entry is a map before accessing keys
        if (entry is Map) {
          return {
            'q': entry['q']?.toString() ?? '', // Ensure values are strings
            'a': entry['a']?.toString() ?? ''
          };
        }
        return {'q': '', 'a': ''}; // Default for malformed entries
      }).toList();
    } catch (e) {
      print('Error getting entries for factsheet $factsheetId, user $_userId: $e');
      return [];
    }
  }
  
  // Delete a factsheet from the user's subcollection
  Future<bool> deleteFactsheet(String factsheetId) async {
    if (_userId == null) {
      print('DeleteFactsheet: User not logged in.');
      return false;
    }

    try {
      print('Attempting to delete factsheet: $factsheetId for user: $_userId');
      
      // The path itself ensures we are targeting the user's factsheet.
      // Security rules will enforce if this user can delete it.
      final docRef = _userFactsheetDocument(factsheetId);
      
      // Optional: Check existence if you want to return a more specific false
      // final docSnapshot = await docRef.get();
      // if (!docSnapshot.exists) {
      //   print('Factsheet $factsheetId does not exist for user $_userId.');
      //   return false;
      // }
      
      await docRef.delete();
      print('Factsheet $factsheetId deleted successfully for user: $_userId');
      return true;
    } catch (e) {
      print('Error deleting factsheet $factsheetId for user $_userId: $e');
      return false;
    }
  }
  // Get all GLOBAL read-only factsheets
  Future<List<FactSheet>> getAllGlobalFactsheets() async {
    try {
      print('Fetching all global factsheets');
      final snapshot = await _firestore
          .collection('globalFactsheets') // Target the new global collection
          .orderBy('comm') // Or 'dateAdded', or any other relevant field for ordering
          .get();
      
      print('Fetched ${snapshot.docs.length} global factsheets');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FactSheet(
          id: doc.id,
          name: data['comm'] ?? 'Unnamed Global Sheet',
          entryCount: data['entryCount'] ?? 0,
          entries: [], // Keep empty for summary list
               isGlobal: true, // Add a flag to differentiate in the UI/model
        );
      }).toList();
    } catch (e) {
      print('Error getting global factsheets: $e');
      return [];
    }
  }

  // Get entries from a specific GLOBAL factsheet
  Future<List<Entry>> getEntriesFromGlobalFactsheet(String factsheetId) async {
    try {
      print('Fetching entries for global factsheet: $factsheetId');
      final docSnapshot = await _firestore.collection('globalFactsheets').doc(factsheetId).get();
      
      if (!docSnapshot.exists) {
        print('Global factsheet $factsheetId does not exist.');
        return [];
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> rawEntries = data['entries'] ?? [];
      print('Fetched ${rawEntries.length} entries for global factsheet $factsheetId');
      
      return rawEntries.map<Map<String, String>>((entry) {
        if (entry is Map) {
          return {
            'q': entry['q']?.toString() ?? '',
            'a': entry['a']?.toString() ?? ''
          };
        }
        return {'q': '', 'a': ''};
      }).toList();
    } catch (e) {
      print('Error getting entries for global factsheet $factsheetId: $e');
      return [];
    }
  }
  // Update a factsheet name in the user's subcollection
  Future<bool> renameFactsheet(String factsheetId, String newName) async {
    if (_userId == null) {
      print('RenameFactsheet: User not logged in.');
      return false;
    }

    try {
      print('Renaming factsheet $factsheetId to "$newName" for user: $_userId');
      
      final docRef = _userFactsheetDocument(factsheetId);
      
      // Optional: Check existence first
      // final docSnapshot = await docRef.get();
      // if (!docSnapshot.exists) {
      //   print('Factsheet $factsheetId does not exist for user $_userId.');
      //   return false;
      // }

      await docRef.update({
        'comm': newName,
        'dateModified': FieldValue.serverTimestamp(),
      });
      
      print('Factsheet $factsheetId renamed successfully for user: $_userId');
      return true;
    } catch (e) {
      print('Error renaming factsheet $factsheetId for user $_userId: $e');
      return false;
    }
  }
  
  // Add new entries to existing factsheet in the user's subcollection
  Future<bool> addEntriesToFactsheet(String factsheetId, List<Map<String, String>> newEntries) async {
    if (_userId == null) {
      print('AddEntries: User not logged in.');
      return false;
    }
    if (newEntries.isEmpty) {
        print('AddEntries: No new entries to add.');
        return true; // Or false if this is an error condition for you
    }

    try {
      print('Adding ${newEntries.length} entries to factsheet: $factsheetId for user: $_userId');
      final docRef = _userFactsheetDocument(factsheetId);
      
      // Use a transaction to robustly update entries
      return await _firestore.runTransaction<bool>((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        if (!docSnapshot.exists) {
          print('Factsheet $factsheetId does not exist for user $_userId in transaction.');
          throw Exception('Factsheet not found'); // Causes transaction to fail
        }
        
        final data = docSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> existingRawEntries = data['entries'] ?? [];
        
        // Convert existing entries to the correct type if needed
        final List<Map<String, String>> existingEntries = existingRawEntries.map<Map<String, String>>((entry) {
            if (entry is Map) {
                return {'q': entry['q']?.toString() ?? '', 'a': entry['a']?.toString() ?? ''};
            }
            return {'q': '', 'a': ''};
        }).toList();

        final formattedNewEntries = newEntries.map((e) => {
          'q': e['q'] ?? '',
          'a': e['a'] ?? ''
        }).toList();
        
        final updatedEntries = [...existingEntries, ...formattedNewEntries];

        // Premium/Limit checks for total entries would go here if you have them
        // Example:
        // final userProfileDoc = await transaction.get(_firestore.collection('users').doc(_userId!));
        // final isPremium = userProfileDoc.data()?['premiumUser'] == true;
        // if (!isPremium && updatedEntries.length > 50) {
        //   print('Free user entry limit (50) reached for factsheet $factsheetId.');
        //   throw Exception('Entry limit reached'); 
        // }
        
        transaction.update(docRef, {
          'entries': updatedEntries,
          'entryCount': updatedEntries.length,
          'dateModified': FieldValue.serverTimestamp(),
        });
        return true;
      });
      
    } catch (e) {
      print('Error adding entries to factsheet $factsheetId for user $_userId: $e');
      return false; // Transaction failed or other error
    }
  }
  
  // Toggle sharing status of a factsheet in the user's subcollection
  Future<bool> toggleFactsheetSharing(String factsheetId, bool isShared) async {
    if (_userId == null) {
      print('ToggleSharing: User not logged in.');
      return false;
    }

    try {
      print('Toggling sharing for factsheet $factsheetId to $isShared for user: $_userId');
      final docRef = _userFactsheetDocument(factsheetId);
      
      // Using a transaction is good practice for updates that might depend on current state,
      // though for a simple toggle, a direct update might also be fine if conflicts are unlikely.
      return _firestore.runTransaction<bool>((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        if (!docSnapshot.exists) {
          print('Factsheet $factsheetId does not exist for user $_userId in transaction.');
          throw Exception('Factsheet not found');
        }
        
        // Ownership is primarily handled by path and rules.
        // This check is redundant if rules are set correctly.
        // final data = docSnapshot.data() as Map<String, dynamic>;
        // if (data['ownerId_if_you_still_have_it'] != _userId) {
        //   throw Exception('User does not own this factsheet');
        // }
        
        transaction.update(docRef, {
          'isShared': isShared, // Make sure your factsheet model supports this field
          'dateModified': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (e) {
      print('Error toggling sharing for factsheet $factsheetId, user $_userId: $e');
      return false;
    }
  }
}