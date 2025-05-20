import 'package:flutter/material.dart';
// Make sure FirestoreManager is accessible or pass its instance/methods

/// Model for a single fact sheet
typedef Entry = Map<String, String>;

class FactSheet {
  final String id;
  final String name;
  final List<Entry> entries; // Usually empty in the list view, loaded on demand
  final int entryCount;
  final bool isGlobal; // True if this is from the global collection

  FactSheet({
    required this.id,
    required this.name,
    required this.entries,
    required this.entryCount,
    this.isGlobal = false, // Default to not global
  });
}

/// Callback signatures
typedef LoadUserSheetsCallback = Future<List<FactSheet>> Function();
typedef LoadGlobalSheetsCallback = Future<List<FactSheet>> Function();
typedef SaveSheetCallback = Future<String?> Function(String name, List<Entry> entries); // For new sheets
typedef DeleteSheetCallback = Future<bool> Function(String sheetId);
typedef RenameSheetCallback = Future<bool> Function(String sheetId, String newName);
// Callback to load a sheet's content (user's or global) back into the main screen's editor
typedef OpenSheetInEditorCallback = Future<void> Function(FactSheet sheet);


class FactSheetsScreen extends StatefulWidget {
  final LoadUserSheetsCallback loadUserSheets;
  final LoadGlobalSheetsCallback loadGlobalSheets;
  final SaveSheetCallback saveSheet;
  final DeleteSheetCallback deleteSheet;
  final RenameSheetCallback renameSheet;
  final OpenSheetInEditorCallback openSheetInEditor; // Used for both user and global sheets


  const FactSheetsScreen({
    super.key,
    required this.loadUserSheets,
    required this.loadGlobalSheets,
    required this.saveSheet,
    required this.deleteSheet,
    required this.renameSheet,
    required this.openSheetInEditor,
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
          _userSheets = results[0]; // No need to cast if typedefs are correct
          _globalSheets = results[1]; // No need to cast
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
              SnackBar(content: Text('Failed to save sheet "$name".')),
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
              ? 'View the content of global sheet "${_selectedSheet!.name}"?'
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
        await widget.openSheetInEditor(_selectedSheet!); // Single callback for both
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_selectedSheet!.isGlobal 
                ? 'Viewing global sheet "${_selectedSheet!.name}".'
                : 'Sheet "${_selectedSheet!.name}" loaded into editor.')),
          );
          // Optionally pop this screen only if it's a user sheet being loaded for editing
          if (!_selectedSheet!.isGlobal) {
               Navigator.pop(context);
          }
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
          _reloadData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete sheet.')),
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
          _reloadData();
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rename sheet.')),
            );
           }
        }
      });
    }
  }
  
  Widget _buildSheetList(List<FactSheet> sheets, String title) {
    if (sheets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No $title available.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall), // Use headlineSmall for better hierarchy
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
                trailing: IconButton(
                  icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'View/Load Sheet',
                  onPressed: () {
                     setState(() { _selectedSheet = sheet; });
                     _handleLoadSelectedSheet();
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
                  icon: Icon(Icons.add_circle_outline), // Changed icon
                  label: Text('Save Current as New'),
                  onPressed: _isLoading ? null : _handleCreateNewSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.file_download_done_outlined), // Changed icon
                  label: Text('View/Load Selected'),
                  onPressed: _isLoading || !canLoadSelected ? null : _handleLoadSelectedSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.drive_file_rename_outline), // Changed icon
                  label: Text('Rename Selected'),
                  onPressed: _isLoading || !canModifySelected ? null : _handleRenameSelectedSheet,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.delete_sweep_outlined), // Changed icon
                  label: Text('Delete Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white // Ensure text is visible
                  ),
                  onPressed: _isLoading || !canModifySelected ? null : _handleDeleteSelectedSheet,
                ),
              ],
            ),
          ),
          if (_isLoadingUserSheets || _isLoadingGlobalSheets) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator( // Added RefreshIndicator
              onRefresh: _reloadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Ensures scrollability for RefreshIndicator
                child: Column(
                  children: [
                    if (_isLoadingUserSheets && _userSheets.isEmpty) 
                      Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Loading your sheets..."))),
                    _buildSheetList(_userSheets, "Your Sheets"),
                    SizedBox(height: 16),
                    if (_isLoadingGlobalSheets && _globalSheets.isEmpty) 
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