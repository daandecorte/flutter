import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/device.dart';
import 'package:project/models/reservation.dart';
import 'profile-screen.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  List<Reservation> userReservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .get();

    setState(() {
      userReservations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Reservation.fromMap(doc.id, data);
      }).toList();
      isLoading = false;
    });
  }

  Future<Device?> _getDevice(String deviceId) async {
    final doc = await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
    if (!doc.exists) return null;
    return Device.fromMap(doc.id, doc.data()!);
  }

  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mijn Reservaties"),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userReservations.isEmpty
              ? const Center(child: Text("Geen reservaties gevonden."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = userReservations[index];
                    return FutureBuilder<Device?>(
                      future: _getDevice(reservation.deviceId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          );
                        }

                        final device = snapshot.data;
                        if (device == null) {
                          return const Card(
                            child: ListTile(title: Text("Apparaat niet gevonden")),
                          );
                        }
                        final imageBytes = base64Decode(device.image);
                        final dateFormat = DateFormat('dd MMM yyyy', 'nl_NL');

                        final days = _calculateDays(reservation.startTime, reservation.endTime);
                        final totalPrice = days * device.price;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    imageBytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Start: ${dateFormat.format(reservation.startTime)}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Einde: ${dateFormat.format(reservation.endTime)}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Prijs per dag: €${device.price.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "Totaal: €${totalPrice.toStringAsFixed(2)} (${days} dagen)",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
