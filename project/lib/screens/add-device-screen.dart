import 'dart:typed_data';
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
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if(res!=null) {
      setState(() {
        selectedImage=res.files.first.bytes;
      });
    }
  }
  Future<void> uploadDevice() async {
    if(selectedImage==null) return;
    final storageRef = FirebaseStorage.instance.ref('devices/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await storageRef.putData(selectedImage!);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final device = Device(
      id: '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: double.parse(priceController.text.trim()),
      category: selectedCategory,
      imageUrl: imageUrl
    );

    await FirebaseFirestore.instance.collection('devices').add(device.toMap());
    Navigator.pop(context);
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("toestel toevoegen")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameController,),
            TextField(controller: descriptionController,),
            TextField(controller: priceController,),
            DropdownButton(
              value: selectedCategory, 
              onChanged: (value) => selectedCategory=value!, 
              items: [
                DropdownMenuItem(value: "Keuken", child: Text("Keuken")),
                DropdownMenuItem(value: "Poetsen", child: Text("Poetsen")),
                DropdownMenuItem(value: "Tuin", child: Text("Tuin"))
              ]
            ),
            ElevatedButton.icon(onPressed: pickImage, label: const Text("kies afbeelding"), icon: const Icon(Icons.image),),
            ElevatedButton(onPressed: uploadDevice, child: const Text("Toestel toevoegen"))
          ],
        )
      )
    );
  }
}