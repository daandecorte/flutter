import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:project/models/device.dart';
import 'package:project/screens/map-screen.dart';

class AddDevice extends StatefulWidget {
  const AddDevice({super.key});

  @override
  State<AddDevice> createState() {
    return AddDeviceState();
  }
}
class AddDeviceState extends State<AddDevice> {

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  String selectedCategory = 'Keuken';
  Uint8List? selectedImage;
  LatLng? selectedLocation;
  String? selectedAddress;
  String? shortAddress;

Future<void> changeCategory(String category) async {
  setState(() {
    selectedCategory=category;  
  });
}
Future<void> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  const maxSizeInBytes = 1048576;

  if (result != null && result.files.single.bytes != null) {
    if(result.files.single.bytes!.length>=maxSizeInBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deze afbeelding is te groot. Max 1MB')),
      );
    }else {
      setState(() {
        selectedImage = result.files.single.bytes;
      });
    }
  } else {
    print("No image selected.");
  }
}
  Future<void> uploadDevice() async {
    if (nameController.text.trim().isEmpty ||
      descriptionController.text.trim().isEmpty ||
      priceController.text.trim().isEmpty ||
      selectedImage == null || 
      selectedLocation == null
      ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul alle velden in en kies een afbeelding en locatie')),
      );
      return;
    }
    double? price = double.tryParse(priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geef een geldige prijs op')),
    );
      return;
    }
    try {
    final storageRef = FirebaseStorage.instance.ref('devices/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final base64Image = base64Encode(selectedImage!);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final userId = user.uid;

    final device = Device(
      id: '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: double.parse(priceController.text.trim()),
      category: selectedCategory,
      image: base64Image,
      user: userId,
      lat: selectedLocation?.latitude ?? 0,
      long: selectedLocation?.longitude ?? 0,
      locationStringFull: selectedAddress ?? "",
      locationStringShort: shortAddress ?? "",
    );

    await FirebaseFirestore.instance.collection('devices').add(device.toMap());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toestel toegevoegd!')),
    );
    Navigator.pop(context);
    } catch (e) {
    print("Upload error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Er is iets misgegaan bij het uploaden')),
    );
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toestel toevoegen")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Naam van het product")),
            TextField(controller: descriptionController,decoration: const InputDecoration(labelText: "Beschrijving")),
            TextField(controller: priceController,decoration: const InputDecoration(labelText: "Prijs in €")),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Categorie:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                DropdownButton(
                  value: selectedCategory, 
                  onChanged: (value) => changeCategory(value!), 
                  items: [
                    DropdownMenuItem(value: "Keuken", child: Text("Keuken")),
                    DropdownMenuItem(value: "Poetsen", child: Text("Poetsen")),
                    DropdownMenuItem(value: "Tuin", child: Text("Tuin"))
                  ]
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    );
                    
                    if (result != null) {
                      setState(() {
                        selectedLocation = result['location'] as LatLng;
                        selectedAddress = result['address'] as String;
                        shortAddress = result['shortAddress'] as String;
                      });
                    }
                  },
                  icon: Icon(Icons.map, size: 30,),
                  label: Text("Kies locatie op de kaart", style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 16,),
                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Locatie gekozen: $selectedAddress',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
              ]
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.memory(
                  selectedImage!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: pickImage, label: const Text("Kies afbeelding", style: TextStyle(fontSize: 15)), icon: const Icon(Icons.image),),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: uploadDevice, child: const Text("Toestel toevoegen", style: TextStyle(fontSize: 15),), )
          ],
        )
      )
    );
  }
}