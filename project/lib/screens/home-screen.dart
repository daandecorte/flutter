import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:project/screens/auth-screen.dart';
import 'package:project/screens/detail-screen.dart';
import 'package:project/screens/device-map-screen.dart';
import 'package:project/screens/map-screen.dart';
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
    LatLng? selectedLocation;

Future<void> getFilteredDevices() async {
  if (!mounted) return;
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

    if (!mounted) return;

    List<Map<String, dynamic>> devices = querySnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    if (selectedLocation != null) {
      devices.sort((a, b) {
        double distanceA = calculateDistance(
          selectedLocation!.latitude, 
          selectedLocation!.longitude, 
          a["lat"], 
          a["long"]
        );
        double distanceB = calculateDistance(
          selectedLocation!.latitude, 
          selectedLocation!.longitude, 
          b["lat"], 
          b["long"]
        );
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      userDevices = devices;
      isLoading = false;
    });

  } catch (e) {
    print("Error fetching devices: $e");
    if (!mounted) return;
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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var distance = Distance();
    return distance.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
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
                    const Text("Search On Map: ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.map),
                      iconSize: 30,
                      onPressed: () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(builder: (context) => const MapScreen()),
                        );
                        
                        if (result != null) {
                          setState(() {
                            selectedLocation = result['location'] as LatLng;
                            getFilteredDevices();
                          });
                        }
                      },
                    )
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
                                const SizedBox(height: 4),
                                if (selectedLocation != null) 
                                  Text(
                                    "Distance: ${calculateDistance(
                                      selectedLocation?.latitude ?? 0,
                                      selectedLocation?.longitude ?? 0,
                                      device['lat'],
                                      device['long'],
                                    ).toStringAsFixed(2)} km",
                                  )
                                else 
                                  Text(
                                    "Lat: ${device['lat']}, Long: ${device['long']}",
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