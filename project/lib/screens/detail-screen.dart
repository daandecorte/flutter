import 'dart:convert';
import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Toestel Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
GestureDetector(
                onTap: () {
                  // Navigate to full-screen image view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageScreen(
                        imageData: device['image'],
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: device['name'], // Unique tag for hero transition
                  child: Image.memory(
                    base64Decode(device['image']),
                    fit: BoxFit.cover,
                    width: 600,  // Control size on device detail page
                    height: double.infinity,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Naam: ${device['name']}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categorie: ${device['category']}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Beschrijving: ${device['description']}' ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prijs: €${device['price'].toString()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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