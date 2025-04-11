import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project/models/device.dart';

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

Future<void> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null && result.files.single.bytes != null) {
    setState(() {
      selectedImage = result.files.single.bytes;
    });
  } else {
    print("No image selected.");
  }
}
  Future<void> uploadDevice() async {
    if(selectedImage==null) return;
    final storageRef = FirebaseStorage.instance.ref('devices/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final base64Image = base64Encode(selectedImage!);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final userId = user.uid; // Get the UID of the logged-in user

    final device = Device(
      id: '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: double.parse(priceController.text.trim()),
      category: selectedCategory,
      image: base64Image,
      user: userId
    );

    await FirebaseFirestore.instance.collection('devices').add(device.toMap());
    Navigator.pop(context);
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
            TextField(controller: priceController,decoration: const InputDecoration(labelText: "Prijs")),
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
                  onChanged: (value) => selectedCategory=value!, 
                  items: [
                    DropdownMenuItem(value: "Keuken", child: Text("Keuken")),
                    DropdownMenuItem(value: "Poetsen", child: Text("Poetsen")),
                    DropdownMenuItem(value: "Tuin", child: Text("Tuin"))
                  ]
                ),
              ]
            ),

            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: pickImage, label: const Text("kies afbeelding"), icon: const Icon(Icons.image),),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: uploadDevice, child: const Text("Toestel toevoegen"))
          ],
        )
      )
    );
  }
}