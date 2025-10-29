import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exp2/database/db_helper.dart';
import 'package:exp2/text_recognition_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({required this.userId, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> items = [];
  final dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final data = await dbHelper.getItemsByUser(widget.userId);
    setState(() {
      items = data;
    });
  }

  Future<void> _deleteItem(int id) async {
    await dbHelper.deleteItem(id);
    _loadItems();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Saved Items'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No items saved yet'),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: item['imagePath'] != null && item['imagePath'] != ''
                        ? Image.file(
                            File(item['imagePath']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.inventory_2, color: Colors.teal),
                    title: Text(item['productName'] ?? 'Unnamed'),
                    subtitle: Text('Expiry: ${item['expiryDate'] ?? 'N/A'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextRecognitionScreen(userId: widget.userId),
          ),
        );
      },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
