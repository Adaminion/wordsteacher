import 'package:flutter/material.dart';

/// Model for a single fact sheet
typedef Entry = Map<String, String>;

class FactSheet {
  final String id;
  final String name;
  final List<Entry> entries;

  FactSheet({required this.id, required this.name, required this.entries});
}

/// Callback signatures
typedef LoadSheetsCallback = Future<List<FactSheet>> Function();
typedef SaveSheetCallback = Future<String?> Function(String name, List<Entry> entries);

class FactSheetsScreen extends StatefulWidget {
  final LoadSheetsCallback loadSheets;
  final SaveSheetCallback saveSheet;

  const FactSheetsScreen({
    super.key,
    required this.loadSheets,
    required this.saveSheet,
  });

  @override
  _FactSheetsScreenState createState() => _FactSheetsScreenState();
}

class _FactSheetsScreenState extends State<FactSheetsScreen> {
  late Future<List<FactSheet>> _sheetsFuture;

  @override
  void initState() {
    super.initState();
    _reloadSheets();
  }

  void _reloadSheets() {
    setState(() {
      _sheetsFuture = widget.loadSheets();
    });
  }

  Future<void> _createNewSheet() async {
    final nameController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('New Sheet Name'),
        content: TextField(controller: nameController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text.trim()), child: Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      // Example: empty entries initially
      await widget.saveSheet(result, []);
      _reloadSheets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fact Sheets')),
      body: FutureBuilder<List<FactSheet>>(
        future: _sheetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final sheets = snapshot.data ?? [];
          if (sheets.isEmpty) {
            return Center(child: Text('No sheets yet'));
          }
          return ListView.builder(
            itemCount: sheets.length,
            itemBuilder: (_, i) {
              final sheet = sheets[i];
              return ListTile(
                title: Text(sheet.name),
                subtitle: Text('${sheet.entries.length} entries'),
                onTap: () {
                  // navigate to editor if needed
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
