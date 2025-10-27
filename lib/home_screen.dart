import 'package:exp2/text_recognition_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await _authService.signOut();
    // Stream in main will redirect to login automatically
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'No email';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.person_outline, size: 36),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Logged in user'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your tracked items will appear here.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: 0, // placeholder; wire up Firestore items later
                itemBuilder: (context, index) {
                  return const ListTile(title: Text('Placeholder item'));
                },
              ),
            ),
           ElevatedButton.icon( onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const TextRecognitionScreen())); }, icon: const Icon(Icons.add), label: const Text('Add item'), )
          ],
        ),
      ),
    );
  }
}
