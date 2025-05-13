import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return ReservationManagementState();
  }
}
class ReservationManagementState extends State<ReservationManagementScreen> {
  List<Map<String, dynamic>> userReservations = [];
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
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  @override
  void initState() {
    super.initState();
    getUserReservations();
    print(userReservations.length);
  }
  @override
  Widget build(BuildContext context) {
    int counter = 0;
    return Text("hey");
  }
}