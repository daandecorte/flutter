import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/screens/add-device-screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profiel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDevice()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 100),
            const SizedBox(height: 20),
            Text(
              user?.email ?? "Geen e-mail gevonden",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log uit"),
            )
          ],
        ),
      ),
    );
  }
}