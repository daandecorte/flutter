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

  @override 
  void initState() {
    super.initState();
    checkOwner();
  }
  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  final isSmallScreen = screenWidth < 970;

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
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildDetailContent(context, screenWidth),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
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
                              height: 600,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildDetailTexts(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: isOwner
              ? ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RentingManagementScreen(device: widget.device),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  label: const Text("Beheer Apparaat"),
                  icon: Icon(Icons.description),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReserveDeviceScreen(device: widget.device),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  label: const Text("Reserveer"),
                  icon: Icon(Icons.calendar_today)
                ),
        ),
      ],
    ),
  );
}

List<Widget> _buildDetailContent(BuildContext context, double screenWidth) {
  return [
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FullScreenImageScreen(imageData: widget.device.image),
          ),
        );
      },
      child: Hero(
        tag: widget.device.name,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(widget.device.image),
            fit: BoxFit.cover,
            width: screenWidth,
            height: 500,
          ),
        ),
      ),
    ),
    const SizedBox(height: 24),
    ..._buildDetailTexts(),
  ];
}

List<Widget> _buildDetailTexts() {
  return [
    Text(
      widget.device.name,
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
      'Prijs: €${widget.device.price.toStringAsFixed(2)}/Dag',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 16),
    Text(
      "Locatie: ${widget.device.locationStringFull}",
      style: const TextStyle(fontSize: 18),
    ),
  ];
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