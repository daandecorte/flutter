import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/models/reservation.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return ReservationManagementState();
  }
}
class ReservationManagementState extends State<ReservationManagementScreen> {
  List<Reservation> userReservations = [];
  Future<void> getUserReservations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      userReservations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Reservation.fromMap(doc.id, data);
      }).toList();
    });
  }
  @override
  void initState() {
    super.initState();
    getUserReservations();
  }
@override
Widget build(BuildContext context) {
  if (userReservations.isEmpty) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return Scaffold(
    appBar: AppBar(title: Text("Mijn Reservaties"),),
    body: Expanded(
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: userReservations.map<Widget>((reservation) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              title: Text(reservation.userId),
              subtitle: Text(reservation.deviceId),
            ),
          );
        }).toList(),
      ),
    ),
  ),
  );
}
}