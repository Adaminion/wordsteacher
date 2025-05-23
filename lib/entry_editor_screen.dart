// © Adaminion 2025 2505220950
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard

class EntryEditorScreen extends StatefulWidget {
  final List<Map<String, String>> initialEntries;
  final String sheetName;

  const EntryEditorScreen({
    super.key,
    required this.initialEntries,
    required this.sheetName,
  });

  @override
  _EntryEditorScreenState createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late List<Map<String, String>> _currentEntries;
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final FocusNode _qFocusNode = FocusNode();
  final FocusNode _aFocusNode = FocusNode();
  int? _editingIndex;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial entries to avoid modifying the original list directly
    _currentEntries = widget.initialEntries.map((entry) => Map<String, String>.from(entry)).toList();
  }

  @override
  void dispose() {
    _qController.dispose();
    _aController.dispose();
    _qFocusNode.dispose();
    _aFocusNode.dispose();
    super.dispose();
  }

  void _addEntry() {
    if (_qController.text.trim().isEmpty || _aController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question and Answer cannot be empty.')),
      );
      return;
    }
    setState(() {
      _currentEntries.add({'q': _qController.text.trim(), 'a': _aController.text.trim()});
      _qController.clear();
      _aController.clear();
      _hasChanges = true;
      _qFocusNode.requestFocus();
    });
  }

  void _startEditEntry(int index) {
    setState(() {
      _editingIndex = index;
      _qController.text = _currentEntries[index]['q']!;
      _aController.text = _currentEntries[index]['a']!;
      _qFocusNode.requestFocus();
    });
  }

  void _updateEntry() {
    if (_editingIndex == null) return;
    if (_qController.text.trim().isEmpty || _aController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question and Answer cannot be empty for update.')),
      );
      return;
    }
    setState(() {
      _currentEntries[_editingIndex!] = {'q': _qController.text.trim(), 'a': _aController.text.trim()};
      _qController.clear();
      _aController.clear();
      _editingIndex = null;
      _hasChanges = true;
      _qFocusNode.requestFocus();
    });
  }

  void _deleteEntry(int index) {
    // Confirmation dialog before deleting
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Are you sure you want to delete the entry: "${_currentEntries[index]['q']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          // If deleting the entry currently being edited, clear the form
          if (_editingIndex == index) {
            _qController.clear();
            _aController.clear();
            _editingIndex = null;
          } else if (_editingIndex != null && index < _editingIndex!) {
            // Adjust editing index if an item before it was deleted
            _editingIndex = _editingIndex! - 1;
          }
          _currentEntries.removeAt(index);
          _hasChanges = true;
        });
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _qController.clear();
      _aController.clear();
      _editingIndex = null;
      _qFocusNode.requestFocus();
    });
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to discard them and go back?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard & Go Back')),
          ],
        ),
      );
      if (confirm == true) {
        Navigator.pop(context, null); // Return null to indicate no changes should be saved from this screen
        return false; // Prevent default pop, already handled by explicit Navigator.pop
      }
      return false; // Stay on the screen, do not pop
    }
    // If no changes, pop normally. Return null as no changes were made.
    Navigator.pop(context, null);
    return false; // Prevent default pop, already handled by explicit Navigator.pop
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit: ${widget.sheetName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.paste_outlined), // Changed icon
              tooltip: 'Paste from Clipboard',
              onPressed: _pasteIntoEditor,
            ),
            IconButton(
              icon: const Icon(Icons.done_all), // Changed icon
              tooltip: 'Save & Close',
              onPressed: () {
                // Return the modified list (or original if no changes)
                Navigator.pop(context, _currentEntries);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              _buildEntryListHeader(),
              Expanded(child: _buildEntryList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_editingIndex != null ? 'Edit Entry:' : 'Add New Entry:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _qController,
              focusNode: _qFocusNode,
              decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
              onSubmitted: (_) => _aFocusNode.requestFocus(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aController,
              focusNode: _aFocusNode,
              decoration: const InputDecoration(labelText: 'Answer', border: OutlineInputBorder()),
              onSubmitted: (_) => _editingIndex != null ? _updateEntry() : _addEntry(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editingIndex != null) ...[
                  TextButton(onPressed: _cancelEdit, child: const Text('Cancel Edit')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_as), // Changed icon
                    label: const Text('Update Entry'), // Corrected parameter: label instead of child
                    onPressed: _updateEntry,
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline), // Changed icon
                    label: const Text('Add Entry'), // Corrected parameter: label instead of child
                    onPressed: _addEntry,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildEntryListHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0), // Added some horizontal padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Entries In This Sheet:', style: Theme.of(context).textTheme.titleSmall), // Changed style
          Text('${_currentEntries.length} entr${_currentEntries.length == 1 ? "y" : "ies"}', style: Theme.of(context).textTheme.bodySmall), // Changed style
        ],
      ),
    );
  }


  Widget _buildEntryList() {
    if (_currentEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No entries yet. Add some using the form above!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        )
      );
    }
    return ListView.builder(
      itemCount: _currentEntries.length,
      itemBuilder: (context, index) {
        final entry = _currentEntries[index];
        final isEditingThis = _editingIndex == index;
        return Card(
          elevation: isEditingThis ? 4 : 2, // Adjusted elevation
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Added rounded corners
          color: isEditingThis ? Theme.of(context).primaryColorLight.withOpacity(0.3) : Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0), // Adjusted margin
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Adjusted padding
            title: Text(
              '${index + 1}. ${entry['q']}',
              style: TextStyle(
                fontWeight: isEditingThis ? FontWeight.bold : FontWeight.normal,
                color: isEditingThis ? Theme.of(context).primaryColorDark : null,
              ),
              maxLines: 2, // Allow title to wrap
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                entry['a']!,
                maxLines: 3, // Allow subtitle to wrap more
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            onTap: () => _startEditEntry(index),
            trailing: IconButton(
              icon: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700), // Changed icon
              tooltip: 'Delete Entry',
              onPressed: () => _deleteEntry(index),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pasteIntoEditor() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return; // Check if widget is still in the tree

    if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      return;
    }

    String text = clipboardData.text!;
    List<String> rawLines = text.split('\n');
    List<String> lines = rawLines.map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard contains no processable content.')));
      return;
    }

    bool isCommaSeparated = lines.every((line) {
        int commaCount = ','.allMatches(line).length;
        return commaCount == 1 && !line.startsWith(',') && !line.endsWith(',');
    });


    List<Map<String, String>> pastedEntries = [];
    bool parsingError = false;

    if (isCommaSeparated) {
      for (String line in lines) {
        final parts = line.split(',');
        if (parts.length == 2 && parts[0].trim().isNotEmpty && parts[1].trim().isNotEmpty) {
          pastedEntries.add({'q': parts[0].trim(), 'a': parts[1].trim()});
        } else {
          parsingError = true;
        }
      }
    } else {
      for (int i = 0; i < lines.length; i += 2) {
        if (i + 1 < lines.length && lines[i].trim().isNotEmpty && lines[i+1].trim().isNotEmpty) {
          pastedEntries.add({'q': lines[i].trim(), 'a': lines[i+1].trim()});
        } else {
          parsingError = true;
        }
      }
    }

    if (pastedEntries.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not parse valid entries from clipboard.')));
       return;
    }

    // Corrected type for showDialog
    final choice = await showDialog<String>( // Changed type to String
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste Entries'),
        content: Text('Found ${pastedEntries.length} entries. Append to current list or replace all?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'append'), child: const Text('Append')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'replace'), child: const Text('Replace All')),
        ],
      ),
    );

    if (!mounted || choice == null || choice == 'cancel') return;

    setState(() {
      if (choice == 'replace') {
        _currentEntries.clear();
         _editingIndex = null; // Clear editing state if replacing all
        _qController.clear();
        _aController.clear();
      }
      _currentEntries.addAll(pastedEntries);
      _hasChanges = true;
    });

    String feedback = '${choice == 'replace' ? 'Replaced with' : 'Appended'} ${pastedEntries.length} entries.';
    if (parsingError) feedback += ' Some lines may not have been processed correctly.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
}
