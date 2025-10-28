// lib/saved_items_screen.dart
import 'package:flutter/material.dart';
import 'database/db_helper.dart';

class SavedItemsScreen extends StatefulWidget {
  final String userId;
  const SavedItemsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  final DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final data = await dbHelper.getItemsByUser(widget.userId);
    setState(() {
      items = data;
      _loading = false;
    });
  }

  Future<void> _deleteItem(int id) async {
    await dbHelper.deleteItem(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: 'Refresh',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No items found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(item['productName'] ?? 'Unnamed'),
                        subtitle: Text('MFG: ${item['manufactureDate'] ?? '-'}\nEXP: ${item['expiryDate'] ?? '-'}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _deleteItem(item['id'] as int);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
