import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/screens/auth-screen.dart';
import 'package:project/screens/profile-screen.dart';

class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<StatefulWidget> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {

    List<Map<String, dynamic>> userDevices = [];

    bool isLoading = true;

  Future<void> getFilteredDevices() async {
    String filter = "Keuken";
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('devices')
          .where('category', isEqualTo: filter)
          .get();

      setState(() {
        userDevices = querySnapshot.docs.map((doc) {
          return doc.data();
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching devices: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
    @override
    void initState() {
    super.initState();
    getFilteredDevices();
  }
    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: const Text('Home Screen'),
            actions: [
            IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                },
            ),
            ],
        ),
        body: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) { //pc
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                      ),
                      itemCount: userDevices.length,
                      itemBuilder: (context, index) {
                        final device = userDevices[index];
                        return _buildDeviceCard(device);
                      },
                    );
                  } else { //gsm
                    return ListView.builder(
                      itemCount: userDevices.length,
                      itemBuilder: (context, index) {
                        final device = userDevices[index];
                        return _buildDeviceCard(device);
                      },
                    );
                  }
                },
              ),
      ),
    );
    }
    Widget _buildDeviceCard(Map<String, dynamic> device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          device['image'] != null
              ? Image.memory(
                  base64Decode(device['image']),
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              device['name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              device['category'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}