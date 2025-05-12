import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/screens/add-device-screen.dart';
import 'package:project/screens/auth-screen.dart';
import 'package:project/screens/detail-screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  List<Map<String, dynamic>> userDevices = [];

  Future<void> getUserDevices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('user', isEqualTo: userId)
        .get();

    setState(() {
      userDevices = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  @override
  void initState() {
    super.initState();
    getUserDevices();
  }
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log uit"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Add verhuurderbeheer logic
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text("Verhuurderbeheer"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Add reserveringsbeheer logic
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text("Reserveringsbeheer"),
            ),
            const SizedBox(height: 40),
            const Text("Jouw toestellen", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  children: userDevices.isEmpty
                      ? [const Center(child: CircularProgressIndicator())]
                      : userDevices.map<Widget>((device) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailScreen(device: device),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: ListTile(
                                title: Text(device['name']),
                                subtitle: Text(device['category']),
                                trailing: device['image'] != null
                                    ? Image.memory(base64Decode(device['image']))
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}