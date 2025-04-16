import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/screens/auth-screen.dart';
import 'package:project/screens/detail-screen.dart';
import 'package:project/screens/profile-screen.dart';

class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<StatefulWidget> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {

    List<Map<String, dynamic>> userDevices = [];

    bool isLoading = true;
    String filter = "Alle";

  Future<void> getFilteredDevices() async {
    if(!mounted) return;
    setState(() {
      isLoading = true;
    });
    
    try {
        QuerySnapshot querySnapshot;
        if (filter == "Alle") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('devices')
            .get();
        } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('devices')
            .where('category', isEqualTo: filter)
            .get();
        }
    if(!mounted) return;
    setState(() {
      userDevices = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      isLoading = false;
      });
    } catch (e) {
      print("Error fetching devices: $e");
      if(!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }
  void changeFilter(newFilter) {
    setState(() {
      filter = newFilter;
      isLoading = true;
    });
    getFilteredDevices();
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
        title: const Text('Apparaten Te Huur!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 50,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
                children: [
                    const Text("Filter: ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                    const SizedBox(width: 5,),
                    DropdownButton<String>(
                    value: filter,
                    onChanged: (String? newFilter) {
                        if (newFilter != null) {
                        changeFilter(newFilter);
                        }
                    },
                    items: const [
                        DropdownMenuItem(value: "Alle", child: Text("Alle")),
                        DropdownMenuItem(value: "Keuken", child: Text("Keuken")),
                        DropdownMenuItem(value: "Poetsen", child: Text("Poetsen")),
                        DropdownMenuItem(value: "Tuin", child: Text("Tuin")),
                    ],
                    ),
                ]

            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: userDevices.map((device) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceDetailScreen(device: device)
                            ) 
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            width: 400,
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                device['image'] != null
                                    ? Image.memory(
                                        base64Decode(device['image']),
                                        height: 200,
                                      )
                                    : Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  device['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  device['category'],
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
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
                  height: 150, 
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