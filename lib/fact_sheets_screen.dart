// © Adaminion 2025 2505220950
import 'package:flutter/material.dart';
// Make sure FirestoreManager is accessible or pass its instance/methods

// Assuming Entry and FactSheet models are defined as you had them:
typedef Entry = Map<String, String>;

class FactSheet {
  final String id;
  final String name;
  final List<Entry> entries; // Usually empty for list view, loaded on demand
  final int entryCount;
  final bool isGlobal;

  FactSheet({
    required this.id,
    required this.name,
    this.entries = const [], // Default to empty list
    required this.entryCount,
    this.isGlobal = false,
  });
}

/// Callback signatures
typedef LoadUserSheetsCallback = Future<List<FactSheet>> Function();
typedef LoadGlobalSheetsCallback = Future<List<FactSheet>> Function();
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
  final bool areMainEntriesEmpty;

  const FactSheetsScreen({
    super.key,
    required this.loadUserSheets,
    required this.loadGlobalSheets,
    required this.saveSheet,
    required this.deleteSheet,
    required this.renameSheet,
    required this.openSheetInEditor,
    required this.areMainEntriesEmpty,
  });

  @override
  _FactSheetsScreenState createState() => _FactSheetsScreenState();
}

class _FactSheetsScreenState extends State<FactSheetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FactSheet> _userSheets = [];
  List<FactSheet> _globalSheets = [];
  FactSheet? _selectedSheet; // This will now be context-aware based on the active tab

  bool _isLoadingUserSheets = false;
  bool _isLoadingGlobalSheets = false;
  bool _hasAttemptedLoadGlobalSheets = false; // To load global sheets only once per tab visit initially
  bool _isPerformingAction = false; // For generic actions like save, delete, rename

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUserSheetsData(); // Load user sheets initially
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Clear selection when tab changes
      _clearSelection();
      if (_tabController.index == 1 && !_hasAttemptedLoadGlobalSheets) {
        _loadGlobalSheetsData();
      }
    }
  }

  bool get _isLoading => _isLoadingUserSheets || _isLoadingGlobalSheets || _isPerformingAction;

  void _performAction(Future<void> Function() actionCallback) async {
    if (_isPerformingAction) return;
    if (mounted) {
      setState(() { _isPerformingAction = true; });
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
        setState(() { _isPerformingAction = false; });
      }
    }
  }

  void _clearSelection() {
    if(mounted){
      setState(() { _selectedSheet = null; });
    }
  }

  Future<void> _loadUserSheetsData() async {
    _clearSelection();
    if(mounted) setState(() { _isLoadingUserSheets = true; });
    try {
      final userSheets = await widget.loadUserSheets();
      if (mounted) setState(() { _userSheets = userSheets; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading your sheets: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isLoadingUserSheets = false; });
    }
  }

  Future<void> _loadGlobalSheetsData() async {
    _clearSelection();
    if(mounted) setState(() { _isLoadingGlobalSheets = true; _hasAttemptedLoadGlobalSheets = true; });
    try {
      final globalSheets = await widget.loadGlobalSheets();
      if (mounted) setState(() { _globalSheets = globalSheets; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading global sheets: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isLoadingGlobalSheets = false; });
    }
  }

  Future<void> _refreshCurrentTabData() async {
    if (_tabController.index == 0) {
      await _loadUserSheetsData();
    } else {
      // For global sheets, we reset the flag to allow re-fetching if desired on next explicit refresh
      _hasAttemptedLoadGlobalSheets = false; 
      await _loadGlobalSheetsData();
    }
  }


  Future<void> _handleCreateNewSheet() async {
    // This action is always for user sheets, regardless of active tab.
    // It saves the *current main editor entries* as a new user sheet.
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
        final newSheetId = await widget.saveSheet(name, []); // Pass empty list; main.dart uses its own 'entries'
        if (newSheetId != null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sheet "$name" saved successfully!')));
          _loadUserSheetsData(); // Refresh user sheets list
          if (_tabController.index != 0) _tabController.animateTo(0); // Switch to user sheets tab
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save sheet "$name". User might not be logged in or another error occurred.')));
        }
      });
    }
  }

  Future<void> _handleLoadSelectedSheet() async {
    if (_selectedSheet == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_selectedSheet!.isGlobal ? 'View Global Sheet?' : 'Load User Sheet?'),
        content: Text(
          _selectedSheet!.isGlobal
              ? 'View the content of global sheet "${_selectedSheet!.name}" in the main editor?'
              : 'This will replace your current unsaved entries in the main editor with the content of "${_selectedSheet!.name}". Proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
          Navigator.pop(context); // Pop this screen to return to the main editor
        }
      });
    }
  }

  Future<void> _handleDeleteSelectedSheet() async {
    if (_selectedSheet == null || _selectedSheet!.isGlobal) return; // Can only delete user sheets
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sheet?'),
        content: Text('Are you sure you want to delete "${_selectedSheet!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
       _performAction(() async {
        final success = await widget.deleteSheet(_selectedSheet!.id);
        if (success) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sheet "${_selectedSheet!.name}" deleted.')));
          _loadUserSheetsData(); // Refresh user sheets, which will also clear selection
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete sheet. User might not be logged in or another error occurred.')));
        }
      });
    }
  }

  Future<void> _handleRenameSelectedSheet() async {
    if (_selectedSheet == null || _selectedSheet!.isGlobal) return; // Can only rename user sheets
    final nameController = TextEditingController(text: _selectedSheet!.name);
    final newName = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Sheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Sheet Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _selectedSheet!.name) {
      _performAction(() async {
        final success = await widget.renameSheet(_selectedSheet!.id, newName);
        if (success) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sheet renamed to "$newName".')));
          _loadUserSheetsData(); // Refresh user sheets, which will also clear selection
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to rename sheet. User might not be logged in or another error occurred.')));
        }
      });
    }
  }

  Widget _buildSheetList(List<FactSheet> sheets, bool isLoadingList, String noSheetsMessage) {
    if (isLoadingList && sheets.isEmpty) { // Show loading only if list is empty and actually loading
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }
    if (sheets.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(noSheetsMessage, style: const TextStyle(fontStyle: FontStyle.italic))));
    }

    return ListView.builder(
      key: PageStorageKey<String>(noSheetsMessage), // To preserve scroll position on tab switch
      itemCount: sheets.length,
      itemBuilder: (_, i) {
        final sheet = sheets[i];
        // Determine if this sheet is the currently selected one
        final isSelected = _selectedSheet?.id == sheet.id && _selectedSheet?.isGlobal == sheet.isGlobal;

        return Card(
          elevation: isSelected ? 4.0 : 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            tileColor: isSelected ? Theme.of(context).primaryColorLight.withOpacity(0.3) : null,
            leading: Icon(
              sheet.isGlobal
                ? Icons.public
                : (isSelected ? Icons.check_circle_outline : Icons.folder_shared_outlined), // Changed icons
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color,
            ),
            title: Text(sheet.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text('${sheet.entryCount} entries'),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSheet = null; // Deselect if tapped again
                } else {
                  _selectedSheet = sheet; // Select this sheet
                }
              });
            },
            trailing: IconButton(
              icon: Icon(Icons.file_open_outlined, color: Theme.of(context).colorScheme.secondary), // Changed icon
              tooltip: sheet.isGlobal ? 'View Sheet in Editor' : 'Load Sheet into Editor',
              onPressed: () {
                 setState(() { _selectedSheet = sheet; });
                 _handleLoadSelectedSheet();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canModifySelected = _selectedSheet != null && !_selectedSheet!.isGlobal;
    bool canLoadSelected = _selectedSheet != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sheets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshCurrentTabData,
            tooltip: 'Refresh Current List',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Your Sheets'),
            Tab(icon: Icon(Icons.public), text: 'Global Sheets'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // Increased padding
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Save'),
                  onPressed: (widget.areMainEntriesEmpty || _isLoading) ? null : _handleCreateNewSheet,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download_done_outlined),
                  label: const Text('Load'),
                  onPressed: _isLoading || !canLoadSelected ? null : _handleLoadSelectedSheet,
                ),
                // Rename and Delete only enabled if a user sheet is selected
                ElevatedButton.icon(
                  icon: const Icon(Icons.drive_file_rename_outline),
                  label: const Text('Rename'),
                  onPressed: _isLoading || !canModifySelected ? null : _handleRenameSelectedSheet,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white
                  ),
                  onPressed: _isLoading || !canModifySelected ? null : _handleDeleteSelectedSheet,
                ),
              ],
            ),
          ),
          // LinearProgressIndicator is removed as loading is shown within tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadUserSheetsData, // Specific refresh for user sheets
                  child: _buildSheetList(_userSheets, _isLoadingUserSheets, "No sheets found for your account."),
                ),
                RefreshIndicator(
                  onRefresh: _loadGlobalSheetsData, // Specific refresh for global sheets
                  child: _buildSheetList(_globalSheets, _isLoadingGlobalSheets, "No global sheets available at the moment."),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
