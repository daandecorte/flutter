import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/models/device.dart';
import 'package:project/screens/renting-management-screen.dart';
import 'profile-screen.dart';
import 'dart:convert' as convert;

import 'package:project/screens/reserve-device-screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  DeviceDetailScreen({super.key, required this.device});

  @override
  DeviceDetailState createState() {
    return DeviceDetailState();
  }
}

class DeviceDetailState extends State<DeviceDetailScreen> {
  bool isOwner = false;
  Future<void> checkOwner() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    if (widget.device.user == userId) {
      setState(() {
        isOwner = true;
      });
    }
  }

  Future<String> getLocationString(lat, long) async {
    var urlString =
    'https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${long}&format=json';

    final dataUrl = Uri.parse(urlString);
    final response = await http.get(dataUrl);
    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);
      return jsonResponse['display_name'];
    } else {
      return 'Error getting location';
    }
  }
  @override 
  void initState() {
    super.initState();
    checkOwner();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toestel Details'),
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
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageScreen(
                        imageData: widget.device.image,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: widget.device.name,
                  child: Image.memory(
                    base64Decode(widget.device.image),
                    fit: BoxFit.cover,
                    width: 600,
                    height: double.infinity,
                  ),
                ),
              ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Naam: ${widget.device.name}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Categorie: ${widget.device.category}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Beschrijving: ${widget.device.description}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prijs: €${widget.device.price.toString()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text( "Locatie: ${widget.device.locationStringFull}", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16,),
                  isOwner ?
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RentingManagementScreen()));
                      }, 
                      child: Text("Beheer Apparaat")
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ReserveDeviceScreen(device: widget.device,)));
                      }, 
                      child: Text("Reserveer")
                    )
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageData;

  const FullScreenImageScreen({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Afbeelding"),
      ),
      body: Center(
        child: Hero(
          tag: imageData,
          child: Image.memory(
            base64Decode(imageData),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}