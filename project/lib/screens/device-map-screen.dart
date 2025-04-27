import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project/screens/detail-screen.dart'; 

class DeviceMapScreen extends StatelessWidget {
  final List<Map<String, dynamic>> devices;

  const DeviceMapScreen({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Devices on Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(51.23016715, 4.4161294643975015),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: devices.map((device) {
              double lat = device['lat'];
              double long = device['long'];
              return Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(lat, long),
                child: IconButton( 
                  icon: const Icon(Icons.location_on, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailScreen(device: device),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
