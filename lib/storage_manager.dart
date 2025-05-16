import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'firestore_manager.dart';
//import 'package:intl/intl.dart';

class StorageManagerScreen extends StatefulWidget {
  final List<Map<String, String>> entries;
  final Function(List<Map<String, String>>) onLoadEntries;
  final Function() onSaveEntries;

  const StorageManagerScreen({
    super.key,
    required this.entries,
    required this.onLoadEntries,
    required this.onSaveEntries,
  });
 
  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> with SingleTickerProviderStateMixin {
  List<Reference> files = [];
  List<Map<String, dynamic>> firestoreFiles = [];
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  late TabController _tabController;
  final FirestoreManager _firestoreManager = FirestoreManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFileList();
    _loadFirestoreFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFileList() async {
    if (user == null) return;
    
    setState(() => isLoading = true);
    try {
      final result = await FirebaseStorage.instance.ref(user!.uid).listAll();
      setState(() {
        files = result.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFirestoreFiles() async {
    if (user == null) return;
    
    setState(() => isLoading = true);
    try {
      final files = await _firestoreManager.getAllVocabularyLists();
      setState(() {
        firestoreFiles = files;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading Firestore files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(String filename) async {
    try {
      setState(() => isLoading = true);
      
      // Create content string
      final content = widget.entries.map((e) => '${e['q']}|${e['a']}').join('\n');
      
      // Convert string to bytes using utf8 encoding
      final bytes = utf8.encode(content);
      
      // Upload directly to Firebase Storage
      final ref = FirebaseStorage.instance.ref('${user!.uid}/$filename');
      await ref.putData(Uint8List.fromList(bytes));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved: $filename\n'
                '${widget.entries.length} entries uploaded'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      await _loadFileList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _uploadToFirestore(String filename) async {
    try {
      setState(() => isLoading = true);
      
      // Save to Firestore
      final docId = await _firestoreManager.saveVocabularyList(
        filename, 
        widget.entries
      );
      
      if (docId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved to Firestore: $filename\n'
                '${widget.entries.length} entries uploaded'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      await _loadFirestoreFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _downloadFile(String name) async {
    try {
      setState(() => isLoading = true);
      
      final ref = FirebaseStorage.instance.ref('${user!.uid}/$name');
      final bytes = await ref.getData();
      
      if (bytes == null || bytes.isEmpty) {
        throw Exception('No data received from storage');
      }
      
      // More safely convert bytes to string
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      final newEntries = <Map<String, String>>[];
      for (var line in lines) {
        print(line);
        if (line.contains('|')) {
          var parts = line.split('|');
          if (parts.length >= 2) {
            newEntries.add({
              'q': parts[0],
              'a': parts.length > 1 ? parts[1] : ''
            });
          }
        }
      }
      
     widget.onLoadEntries(newEntries);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded: $name\n'
                '${newEntries.length} entries loaded'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _downloadFromFirestore(String docId, String name) async {
    try {
      setState(() => isLoading = true);
      
      final entries = await _firestoreManager.getEntriesFromList(docId);
      
      if (entries.isEmpty) {
        throw Exception('No entries found in the document');
      }
      
      widget.onLoadEntries(entries);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded from Firestore: $name\n'
                '${entries.length} entries loaded'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading from Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteFile(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => isLoading = true);
      
      final ref = FirebaseStorage.instance.ref('${user!.uid}/$name');
      await ref.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted: $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadFileList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteFirestoreFile(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => isLoading = true);
      
      final success = await _firestoreManager.deleteVocabularyList(docId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted from Firestore: $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadFirestoreFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting from Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _renameFile(String oldName, String newName) async {
    try {
      setState(() => isLoading = true);
      
      final refOld = FirebaseStorage.instance.ref('${user!.uid}/$oldName');
      final refNew = FirebaseStorage.instance.ref('${user!.uid}/$newName');
      
      // Check if new name already exists
      try {
        await refNew.getMetadata();
        throw Exception('A file with this name already exists');
      } catch (e) {
        if (e is! FirebaseException || e.code != 'object-not-found') {
          rethrow;
        }
      }
      
      final data = await refOld.getData();
      if (data == null) throw Exception('Could not read source file');
      
      await refNew.putData(data);
      await refOld.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully renamed "$oldName" to "$newName"'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadFileList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _renameFirestoreFile(String docId, String oldName, String newName) async {
    try {
      setState(() => isLoading = true);
      
      final success = await _firestoreManager.renameVocabularyList(docId, newName);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully renamed "$oldName" to "$newName" in Firestore'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadFirestoreFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming file in Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<String?> _promptFilename({String? initialText}) async {
    final ctrl = TextEditingController(text: initialText);
    bool isValid = true;
    String? errorText;

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(initialText != null ? "Rename File" : "Enter Filename"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Filename',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      errorText = 'Filename cannot be empty';
                      isValid = false;
                    } else if (value.contains('/') || value.contains('\\')) {
                      errorText = 'Filename cannot contain / or \\';
                      isValid = false;
                    } else {
                      errorText = null;
                      isValid = true;
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: isValid
                  ? () => Navigator.pop(context, ctrl.text.trim())
                  : null,
              child: Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return 'Unknown format';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cloud Storage"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Firebase Storage"),
            Tab(text: "Firestore Database"),
          ],
        ),
        actions: [
          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Firebase Storage Tab
          Column(
            children: [
              // File count header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Storage Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total files: ${files.length}',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (widget.entries.isNotEmpty)
                      Text(
                        'Current entries: ${widget.entries.length}',
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              
              // File list
              Expanded(
                child: files.isEmpty
                    ? Center(
                        child: Text(
                          isLoading ? 'Loading...' : 'No files found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          return ListTile(
                            leading: Icon(Icons.insert_drive_file),
                            title: Text(file.name),
                             subtitle: FutureBuilder<FullMetadata>(
                              future: file.getMetadata(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final metadata = snapshot.data!;
                                  final size = metadata.size ?? 0;
                                  final sizeStr = size > 1024
                                      ? '${(size / 1024).toStringAsFixed(1)} KB'
                                      : '$size B';
                                  try {
                                    final time = metadata.updated ?? metadata.timeCreated;
                                    final timeStr = time != null
                                        ? '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                        : 'Unknown date';
                                    return Text('Size: $sizeStr | Modified: $timeStr');
                                  } catch (e) {
                                    return Text('To tu sie zjebalo');
                                  }
                                }
                                return Text('Loading...');
                              },
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'load') {
                                  await _downloadFile(file.name);
                                } else if (value == 'delete') {
                                  await _deleteFile(file.name);
                                } else if (value == 'rename') {
                                  final newName = await _promptFilename(initialText: file.name);
                                  if (newName != null && newName != file.name) {
                                    await _renameFile(file.name, newName);
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'load',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text('Load'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Rename'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          
          // Firestore Tab
          Column(
            children: [
              // File count header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Firestore Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total files: ${firestoreFiles.length}',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (widget.entries.isNotEmpty)
                      Text(
                        'Current entries: ${widget.entries.length}',
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              
              // Firestore file list
              Expanded(
                child: firestoreFiles.isEmpty
                    ? Center(
                        child: Text(
                          isLoading ? 'Loading...' : 'No files found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: firestoreFiles.length,
                        itemBuilder: (context, index) {
                          final file = firestoreFiles[index];
                          return ListTile(
                            leading: Icon(Icons.description),
                            title: Text(file['name'] ?? 'Unnamed'),
                            subtitle: Text(
                          'Entries: ${file['entryCount'] ?? 0} ${file['dateModified'] != null 
                            ? 'Modified: ${_formatTimestamp(file['dateModified'])}'
                            : 'No date'}'
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'load') {
                                  await _downloadFromFirestore(file['id'], file['name']);
                                } else if (value == 'delete') {
                                  await _deleteFirestoreFile(file['id'], file['name']);
                                } else if (value == 'rename') {
                                  final newName = await _promptFilename(initialText: file['name']);
                                  if (newName != null && newName != file['name']) {
                                    await _renameFirestoreFile(file['id'], file['name'], newName);
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'load',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text('Load'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Rename'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: widget.entries.isEmpty
                    ? null
                    : () async {
                        if (widget.entries.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No entries to save'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        
                        final name = await _promptFilename();
                        if (name != null) {
                          // Save to the active tab's storage
                          if (_tabController.index == 0) {
                            await _uploadFile(name); // Firebase Storage
                          } else {
                            await _uploadToFirestore(name); // Firestore
                          }
                        }
                      },
                child: Text('Save As New'),
              ),
              if (widget.entries.isNotEmpty)
                Text(
                  '${widget.entries.length} entries',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}