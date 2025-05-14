import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapState createState() => MapState();
}

class MapState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 14.0;
  String _appBarTitle = 'Klik ergens of zoek uw locatie.';
  final LatLng _initialCenter = LatLng(51.23016715, 4.4161294643975015);

  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchAddressDialog,
          ),
          if (_selectedLocation != null)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _confirmLocation,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _currentZoom,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _findCoords(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'edu.ap.flutter_map',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    _currentZoom += 1;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom -= 1;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _findCoords(LatLng coords) async {
    String lat = coords.latitude.toString();
    String long = coords.longitude.toString();
    var snackText = Text('lat=$lat & long=$long');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: snackText));

    var urlString =
        'https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${long}&format=json';

    final dataUrl = Uri.parse(urlString);
    final response = await http.get(dataUrl);

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);
      setState(() {
        _appBarTitle = jsonResponse['display_name'];
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _appBarTitle,
      }); 
    }
  }

  void _searchAddressDialog() {
    TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zoek adres'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(hintText: 'Geef adres op...'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String address = searchController.text.trim();
              if (address.isNotEmpty) {
                await _searchAddress(address);
              }
            },
            child: Text('Zoek'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    try {
      var url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = convert.jsonDecode(response.body);
        if (data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          final point = LatLng(lat, lon);

          setState(() {
            _selectedLocation = point;
            _mapController.move(point, 16.0);
            _appBarTitle = firstResult['display_name'];
          });
        }
      }
    } catch (e) {
      print('Error searching address: $e');
    }
  }


}
