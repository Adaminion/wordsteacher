import 'package:flutter/material.dart';
// Make sure FirestoreManager is accessible or pass its instance/methods

/// Model for a single fact sheet
typedef Entry = Map<String, String>; // This typedef was defined here. In main.dart it was List<Map<String, String>>. Consistent?
                                    // For FactSheet.entries, it might be better to use List<Map<String, String>> for consistency
                                    // with how 'entries' is handled in main.dart.
                                    // However, if Entry represents a single Q/A pair, then List<Entry> is correct for FactSheet.entries.
                                    // FirestoreManager returns List<Map<String, String>> for getEntriesFrom...
                                    // Let's assume Entry is Map<String, String> and thus List<Entry> for a sheet is correct.


class FactSheet {
  final String id;
  final String name;
  final List<Entry> entries; // List of Q/A pairs
  final int entryCount;
  final bool isGlobal;

  FactSheet({
    required this.id,
    required this.name,
    required this.entries,
    required this.entryCount,
    this.isGlobal = false,
  });
}

/// Callback signatures
typedef LoadUserSheetsCallback = Future<List<FactSheet>> Function();
typedef LoadGlobalSheetsCallback = Future<List<FactSheet>> Function();
// SaveSheetCallback in main.dart's saveSheet implies it saves _memorlyHomeState.entries,
// so the List<Entry> here is for the structure, but the data comes from the main screen.
typedef SaveSheetCallback = Future<String?> Function(String name, List<Map<String, String>> currentMainEntries);
typedef DeleteSheetCallback = Future<bool> Function(String sheetId);
typedef RenameSheetCallback = Future<bool> Function(String sheetId, String newName);
typedef OpenSheetInEditorCallback = Future<void> Function(FactSheet sheet);


class FactSheetsScreen extends StatefulWidget {
  final LoadUserSheetsCallback loadUserSheets;
  final LoadGlobalSheetsCallback loadGlobalSheets;
  final SaveSheetCallback saveSheet;
  final DeleteSheetCallback deleteSheet;
  final RenameSheetCallback renameSheet;
  final OpenSheetInEditorCallback openSheetInEditor;
  final bool areMainEntriesEmpty; // <-- New parameter

  const FactSheetsScreen({
    super.key,
    required this.loadUserSheets,
    required this.loadGlobalSheets,
    required this.saveSheet,
    required this.deleteSheet,
    required this.renameSheet,
    required this.openSheetInEditor,
    required this.areMainEntriesEmpty, // <-- Added to constructor
  });

  @override
  _FactSheetsScreenState createState() => _FactSheetsScreenState();
}

class _FactSheetsScreenState extends State<FactSheetsScreen> {
  List<FactSheet> _userSheets = [];
  List<FactSheet> _globalSheets = [];
  FactSheet? _selectedSheet;
  bool _isLoadingUserSheets = false;
  bool _isLoadingGlobalSheets = false;
  bool _isPerformingAction = false;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  bool get _isLoading => _isLoadingUserSheets || _isLoadingGlobalSheets || _isPerformingAction;

  void _performAction(Future<void> Function() actionCallback) async {
    if (_isPerformingAction) return;
    if (mounted) {
      setState(() {
        _isPerformingAction = true;
      });
    }
    try {
      await actionCallback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAction = false;
        });
      }
    }
  }

  void _clearSelection() {
    if(mounted){
      setState(() {
        _selectedSheet = null;
      });
    }
  }

  Future<void> _reloadData() async {
    _clearSelection();
    if(mounted) {
      setState(() {
        _isLoadingUserSheets = true;
        _isLoadingGlobalSheets = true;
      });
    }

    try {
      final userSheetsFuture = widget.loadUserSheets();
      final globalSheetsFuture = widget.loadGlobalSheets();

      final results = await Future.wait([userSheetsFuture, globalSheetsFuture]);

      if (mounted) {
        setState(() {
          _userSheets = results[0];
          _globalSheets = results[1];
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sheets: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserSheets = false;
          _isLoadingGlobalSheets = false;
        });
      }
    }
  }

  Future<void> _handleCreateNewSheet() async {
    final nameController = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Current Session As New Sheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Sheet Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save New'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _performAction(() async {
        // Pass empty list for screenEntries as the callback uses main 'entries'
        final newSheetId = await widget.saveSheet(name, []);
        if (newSheetId != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sheet "$name" saved successfully!')),
            );
          }
          _reloadData();
        } else {
          if (mounted){
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save sheet "$name". User might not be logged in or another error occurred.')),
            );
          }
        }
      });
    }
  }

  Future<void> _handleLoadSelectedSheet() async {
    if (_selectedSheet == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_selectedSheet!.isGlobal ? 'View Global Sheet?' : 'Load Sheet?'),
        content: Text(
          _selectedSheet!.isGlobal
              ? 'View the content of global sheet "${_selectedSheet!.name}" in the main editor?'
              : 'This will replace your current unsaved entries in the main editor with the content of "${_selectedSheet!.name}". Proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_selectedSheet!.isGlobal ? 'View' : 'Load')),
        ],
      ),
    );

    if (confirm == true) {
      _performAction(() async {
        await widget.openSheetInEditor(_selectedSheet!);
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_selectedSheet!.isGlobal
                ? 'Viewing global sheet "${_selectedSheet!.name}".'
                : 'Sheet "${_selectedSheet!.name}" loaded into editor.')),
          );
          // Pop this screen after loading/viewing to return to the main editor
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _handleDeleteSelectedSheet() async {
    if (_selectedSheet == null || _selectedSheet!.isGlobal) return;
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Sheet?'),
        content: Text('Are you sure you want to delete "${_selectedSheet!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
       _performAction(() async {
        final success = await widget.deleteSheet(_selectedSheet!.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sheet "${_selectedSheet!.name}" deleted.')),
            );
          }
          _reloadData(); // This will also clear selection
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete sheet. User might not be logged in or another error occurred.')),
            );
          }
        }
      });
    }
  }

  Future<void> _handleRenameSelectedSheet() async {
    if (_selectedSheet == null || _selectedSheet!.isGlobal) return;
    final nameController = TextEditingController(text: _selectedSheet!.name);
    final newName = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rename Sheet'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'New Sheet Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _selectedSheet!.name) {
      _performAction(() async {
        final success = await widget.renameSheet(_selectedSheet!.id, newName);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sheet renamed to "$newName".')),
            );
          }
          _reloadData(); // This will also clear selection
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rename sheet. User might not be logged in or another error occurred.')),
            );
           }
        }
      });
    }
  }

  Widget _buildSheetList(List<FactSheet> sheets, String title) {
    if (sheets.isEmpty) {
      // Don't show "Loading..." message here if it's handled by the main CircularProgressIndicator
      // Only show "No sheets available" if not loading
      if (!((title == "Your Sheets" && _isLoadingUserSheets) || (title.startsWith("Global") && _isLoadingGlobalSheets))) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('No $title available.', style: TextStyle(fontStyle: FontStyle.italic))),
        );
      }
      return SizedBox.shrink(); // Show nothing if loading that specific list and it's empty
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sheets.length,
          itemBuilder: (_, i) {
            final sheet = sheets[i];
            final isSelected = _selectedSheet?.id == sheet.id && _selectedSheet?.isGlobal == sheet.isGlobal;
            return Card(
              elevation: isSelected ? 4.0 : 1.0,
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                tileColor: isSelected ? Theme.of(context).primaryColorLight.withOpacity(0.3) : null,
                leading: Icon(
                  sheet.isGlobal
                    ? Icons.public
                    : (isSelected ? Icons.check_circle : Icons.library_books),
                  color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color,
                ),
                title: Text(sheet.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('${sheet.entryCount} entries'),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSheet = null;
                    } else {
                      _selectedSheet = sheet;
                    }
                  });
                },
                trailing: IconButton( // Keep this for quick load/view
                  icon: Icon(Icons.file_download_done_outlined, color: Theme.of(context).colorScheme.secondary),
                  tooltip: sheet.isGlobal ? 'View Sheet in Editor' : 'Load Sheet into Editor',
                  onPressed: () {
                     setState(() { _selectedSheet = sheet; }); // Select first
                     _handleLoadSelectedSheet(); // Then load
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canModifySelected = _selectedSheet != null && !_selectedSheet!.isGlobal;
    bool canLoadSelected = _selectedSheet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Sheets'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _reloadData,
            tooltip: 'Refresh Lists',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Save Current as New'),
                  // Updated onPressed condition
                  onPressed: (widget.areMainEntriesEmpty || _isLoading) ? null : _handleCreateNewSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.file_download_done_outlined),
                  label: Text('View/Load Selected'),
                  onPressed: _isLoading || !canLoadSelected ? null : _handleLoadSelectedSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.drive_file_rename_outline),
                  label: Text('Rename Selected'),
                  onPressed: _isLoading || !canModifySelected ? null : _handleRenameSelectedSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.delete_sweep_outlined),
                  label: Text('Delete Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white
                  ),
                  onPressed: _isLoading || !canModifySelected ? null : _handleDeleteSelectedSheet,
                ),
              ],
            ),
          ),
          if (_isLoadingUserSheets || _isLoadingGlobalSheets) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_isLoadingUserSheets && _userSheets.isEmpty && !_globalSheets.isNotEmpty) // Show only if both are loading or user sheets specifically
                      Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Loading your sheets..."))),
                    _buildSheetList(_userSheets, "Your Sheets"),
                    SizedBox(height: 16),
                     if (_isLoadingGlobalSheets && _globalSheets.isEmpty && !_userSheets.isNotEmpty) // Show only if both are loading or global sheets specifically
                      Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Loading global sheets..."))),
                    _buildSheetList(_globalSheets, "Global Sheets (Read-Only)"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}