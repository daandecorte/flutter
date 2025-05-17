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
  String filter = "huidig";

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isLoading=true;
    });

    final ownDevicesSnapshot = await FirebaseFirestore.instance
    .collection('devices')
    .where('user', isEqualTo: user.uid)
    .get();

    final ownDeviceIds = ownDevicesSnapshot.docs.map((doc) => doc.id).toSet();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .get();

    final allReservations = querySnapshot.docs
        .map((doc) => Reservation.fromMap(doc.id, doc.data()))
        .where((r) => !ownDeviceIds.contains(r.deviceId))
        .toList();

    List<Reservation> filteredReservations;
    final now = DateTime.now();
    if(filter=="huidig") {
      filteredReservations = allReservations.where((r) => !r.endTime.isBefore(now) || r.endTime==now).toList();
    }
    else if(filter=="vorig") {
      filteredReservations = allReservations.where((r) => r.endTime.isBefore(now)).toList();
    }
    else {
      filteredReservations = allReservations;
    }

    filteredReservations.sort((a, b) => a.startTime.compareTo(b.startTime),);
    
    setState(() {
      userReservations = filteredReservations;
      isLoading = false;
    });
  }

  Future<Device?> getDevice(String deviceId) async {
    final doc = await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
    if (!doc.exists) return null;
    return Device.fromMap(doc.id, doc.data()!);
  }

  int calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  void changeFilter(String newFilter) {
    setState(() {
      filter=newFilter;
    });
    fetchReservations();
  }
  bool isReservationActive(Reservation r) {
    final now = DateTime.now();
    return (r.startTime.isBefore(now) || r.startTime.isAtSameMomentAs(now)) && (r.endTime.isAfter(now) || r.endTime.isAtSameMomentAs(now));
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
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Filter: ",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownButton<String>(
              value: filter,
              onChanged: (String? newFilter) {
                if (newFilter != null) {
                  changeFilter(newFilter);
                }
              },
              items: const [
                DropdownMenuItem(value: "huidig", child: Text("Huidige Reservaties")),
                DropdownMenuItem(value: "vorig", child: Text("Vorige Reservaties")),
              ],
            ),
          ]
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : userReservations.isEmpty
                  ? const Center(child: Text("Geen reservaties gevonden."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: userReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = userReservations[index];
                        return FutureBuilder<Device?>(
                          future: getDevice(reservation.deviceId),
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
                            final days = calculateDays(reservation.startTime, reservation.endTime);
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
                                          Row(
                                            children: [
                                            Text(
                                              device.name,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            if (isReservationActive(reservation)) 
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                child: Text(
                                                  'Actief nu',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ),
                                            ],
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
        ),
      ],
    ),
  );
}

}
