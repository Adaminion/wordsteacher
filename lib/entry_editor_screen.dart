
// © Adaminion 2025 2505220950
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// NEW: Import for localization
import 'l10n/app_localizations.dart';

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
    // NEW: Get localizations
    final localizations = AppLocalizations.of(context)!;
    
    if (_qController.text.trim().isEmpty || _aController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        // CHANGED: Use localized message
        SnackBar(content: Text(localizations.questionAndAnswerCannotBeEmpty)),
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

  void _deleteEntry(int index) {
    // NEW: Get localizations
    final localizations = AppLocalizations.of(context)!;
    
    // Confirmation dialog before deleting
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // CHANGED: Use localized title
        title: Text(localizations.deleteEntryTitle),
        // CHANGED: Use localized content with placeholder
        content: Text(localizations.deleteEntryConfirm(_currentEntries[index]['q']!)),
        actions: [
          // CHANGED: Use localized button text
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizations.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            // CHANGED: Use localized delete text
            child: Text(localizations.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          if (_editingIndex == index) {
            _qController.clear();
            _aController.clear();
            _editingIndex = null;
          } else if (_editingIndex != null && index < _editingIndex!) {
            _editingIndex = _editingIndex! - 1;
          }
          _currentEntries.removeAt(index);
          _hasChanges = true;
        });
      }
    });
  }

  Future<bool> _onWillPop() async {
    // NEW: Get localizations
    final localizations = AppLocalizations.of(context)!;
    
    if (_hasChanges) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          // CHANGED: Use localized title
          title: Text(localizations.unsavedChanges),
          // CHANGED: Use localized content
          content: Text(localizations.discardChangesMessage),
          actions: [
            // CHANGED: Use localized button text
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localizations.stay)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(localizations.discardAndGoBack)),
          ],
        ),
      );
      if (confirm == true) {
        Navigator.pop(context, null);
        return false;
      }
      return false;
    }
    Navigator.pop(context, null);
    return false;
  }

  @override
 
  Future<void> _copyAllToClipboard() async {
    if (_currentEntries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries to copy.')),
        );
      }
      return;
    }

    // Ask user for preferred format if entries contain commas, or default to Q,A
    bool hasCommasInEntries = false;
    for (var entry in _currentEntries) {
      if (entry['q']!.contains(',') || entry['a']!.contains(',')) {
        hasCommasInEntries = true;
        break;
      }
    }

    String textToCopy;

    if (hasCommasInEntries) {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false, // User must choose an option
        builder: (ctx) => AlertDialog(
          title: const Text('Commas Detected in Entries'),
          content: const Text('Your entries contain commas. How would you like to format the text for the clipboard?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Line by Line (Q then A)'),
              onPressed: () => Navigator.of(ctx).pop('lineByLine'),
            ),
            TextButton(
              child: const Text('Remove Commas (Q,A)'),
              onPressed: () => Navigator.of(ctx).pop('removeCommas'),
            ),
             TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop('cancel'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copy operation cancelled.')),
          );
        }
        return;
      }

      if (choice == 'lineByLine') {
        textToCopy = _currentEntries.map((e) => '${e['q']}\n${e['a']}').join('\n\n');
      } else { // removeCommas
        textToCopy = _currentEntries.map((e) {
          String question = e['q']!.replaceAll(',', ' ');
          String answer = e['a']!.replaceAll(',', ' ');
          return '$question,$answer';
        }).join('\n');
      }
    } else {
      // Default format: Q,A
      textToCopy = _currentEntries.map((e) => '${e['q']},${e['a']}').join('\n');
    }


    if (textToCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied ${_currentEntries.length} entries to clipboard.')),
        );
      }
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing was copied to clipboard.')),
        );
    }
  }

  Future<void> _pasteIntoEditor() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return; 

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
      // Try Q/A on separate lines
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

    final choice = await showDialog<String>( 
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
         _editingIndex = null; 
        _qController.clear();
        _aController.clear();
      }
      _currentEntries.addAll(pastedEntries);
      _hasChanges = true;
    });

    String feedback = '${choice == 'replace' ? 'Replaced with' : 'Appended'} ${pastedEntries.length} entries.';
    if (parsingError) feedback += ' Some lines may not have been processed correctly.';
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
    }
  }

  void _swapAllQA() {
    if (_currentEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to swap.')),
      );
      return;
    }
    setState(() {
      for (int i = 0; i < _currentEntries.length; i++) {
        final String tempQ = _currentEntries[i]['q']!;
        _currentEntries[i]['q'] = _currentEntries[i]['a']!;
        _currentEntries[i]['a'] = tempQ;
      }
      _hasChanges = true;
      // If currently editing an entry, update the text fields as well
      if (_editingIndex != null) {
          _qController.text = _currentEntries[_editingIndex!]['q']!;
          _aController.text = _currentEntries[_editingIndex!]['a']!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Swapped Q&A for ${_currentEntries.length} entries.')),
    );
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
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Copy All to Clipboard',
              onPressed: _copyAllToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.content_paste_go_outlined), 
              tooltip: 'Paste from Clipboard',
              onPressed: _pasteIntoEditor,
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_outlined),
              tooltip: 'Swap All Q&A',
              onPressed: _swapAllQA,
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline), 
              tooltip: 'Save & Close',
              onPressed: () {
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
                  TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_outlined), // Changed icon
                    label: const Text('Save'), 
                    onPressed: _updateEntry,
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_task_outlined), // Changed icon
                    label: const Text('Addy'), 
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
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Entries In This Sheet:', style: Theme.of(context).textTheme.titleSmall), 
          Text('${_currentEntries.length} entr${_currentEntries.length == 1 ? "y" : "ies"}', style: Theme.of(context).textTheme.bodySmall), 
        ],
      ),
    );
  }


  Widget _buildEntryList() {
    if (_currentEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No entries yet. Add some using the form above or paste from clipboard!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        )
      );
    }
    return ListView.builder(
      itemCount: _currentEntries.length,
      itemBuilder: (context, index) {
        final entry = _currentEntries[index];
        final isEditingThis = _editingIndex == index;
        return Card(
          elevation: isEditingThis ? 4 : 2, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
          color: isEditingThis ? Theme.of(context).primaryColorLight.withOpacity(0.3) : Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0), 
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), 
            title: Text(
              '${index + 1}. ${entry['q']}',
              style: TextStyle(
                fontWeight: isEditingThis ? FontWeight.bold : FontWeight.normal,
                color: isEditingThis ? Theme.of(context).primaryColorDark : null,
              ),
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                entry['a']!,
                maxLines: 3, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            onTap: () => _startEditEntry(index),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700), // Changed icon
              tooltip: 'Delete Entry',
              onPressed: () => _deleteEntry(index),
            ),
          ),
        );
      },
    );
  }
}
