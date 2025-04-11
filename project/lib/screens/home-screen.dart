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
    String filter = "Geen";

  Future<void> getFilteredDevices() async {
    setState(() {
      isLoading = true;
    });
    
    try {
        QuerySnapshot querySnapshot;
        if (filter == "Geen") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('devices')
            .get();
        } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('devices')
            .where('category', isEqualTo: filter)
            .get();
        }

      setState(() {
      userDevices = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
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
                        DropdownMenuItem(value: "Geen", child: Text("Geen")),
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
                child: LayoutBuilder(
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