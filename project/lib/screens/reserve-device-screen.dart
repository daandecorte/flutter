import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReserveDeviceScreen extends StatefulWidget {
  final Map<String, dynamic> device;
  const ReserveDeviceScreen({super.key, required this.device});

  @override
  State<ReserveDeviceScreen> createState() => _ReserveDeviceScreenState();
}

class _ReserveDeviceScreenState extends State<ReserveDeviceScreen> {

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    return Scaffold(
      appBar: AppBar(title: Text("Reserveer apparaat")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(device['name'])
        ),
      );
  }
}