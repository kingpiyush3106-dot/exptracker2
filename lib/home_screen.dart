import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exp2/database/db_helper.dart';
import 'package:exp2/text_recognition_screen.dart';
import 'package:exp2/notification_service.dart'; // 🔔 notification service
import 'package:timezone/timezone.dart' as tz; // ✅ timezone import

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

    // 🧩 Schedule expiry reminders for all loaded items
    for (final item in data) {
      if (item['expiryDate'] != null && item['expiryDate'].toString().isNotEmpty) {
        try {
          DateTime expiry = DateTime.parse(item['expiryDate']);
          await _scheduleReminders(item['productName'] ?? 'Product', expiry);
        } catch (e) {
          print("⚠️ Could not parse expiry date: ${item['expiryDate']} → $e");
        }
      }
    }
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

  // 🔔 Automatically schedule reminders for a product
  Future<void> _scheduleReminders(String name, DateTime expiry) async {
    final reminders = {
      '1 month before': expiry.subtract(const Duration(days: 30)),
      '2 weeks before': expiry.subtract(const Duration(days: 14)),
      '1 week before': expiry.subtract(const Duration(days: 7)),
      '3 days before': expiry.subtract(const Duration(days: 3)),
      '1 day before': expiry.subtract(const Duration(days: 1)),
      'On expiry day': expiry,
    };

    for (final entry in reminders.entries) {
      final date = entry.value;
      if (date.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          title: 'Expiry Reminder ⏰',
          body: '$name expires ${entry.key}!',
          scheduledDate: date,
        );
        print("✅ Scheduled '${entry.key}' notification for $name at $date");
      }
    }
  }

  // 🧪 Manual test notification button
  Future<void> _testNotification() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 5));

    await NotificationService.scheduleNotification(
      title: 'Test Notification 🎉',
      body: 'If you see this, notifications are working!',
      scheduledDate: scheduledDate,
    );

    print("🔔 Test notification scheduled for: ${tz.TZDateTime.from(scheduledDate, tz.local)}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Test notification set for 5 seconds later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Saved Items'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification, // 🔔 test button
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items saved yet'))
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
