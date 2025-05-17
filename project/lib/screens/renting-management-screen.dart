import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:project/models/device.dart';
import 'package:project/models/reservation.dart';
import 'package:project/screens/home-screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'profile-screen.dart';

class RentingManagementScreen extends StatefulWidget {
  final Device device;

  const RentingManagementScreen({super.key, required this.device});

  @override
  State<RentingManagementScreen> createState() {
    return RentingManagementState();
  }
}

class RentingManagementState extends State<RentingManagementScreen> {
  bool isLoading = false;
  List<Reservation> reservations = [];
  List<Reservation> allReservations = [];
  DateTime? unavailableStart;
  DateTime? unavailableEnd;
  DateTime focusedDay = DateTime.now();
  String currentUserId = "";


  @override
  void initState() {
    super.initState();      
    final currentUser = FirebaseAuth.instance.currentUser;
    if(currentUser==null) return;
    currentUserId = currentUser.uid; 
    fetchDeviceReservations();
  }

  Future<void> fetchDeviceReservations() async {
    setState(() {
      isLoading = true;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: widget.device.id)
        .get();

    final fetchedReservations = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Reservation.fromMap(doc.id, data);
    }).toList();

    final filteredReservations = fetchedReservations.where((r) => r.userId!=currentUserId).toList();
    filteredReservations.sort((a, b) => a.startTime.compareTo(b.startTime));

    setState(() {
      reservations = filteredReservations;
      allReservations = fetchedReservations;
      isLoading = false;
    });
  }

  Future<void> blockDevicePeriod() async {
    if (unavailableStart == null || unavailableEnd == null) return;

    await FirebaseFirestore.instance.collection('reservations').add({
      'deviceId': widget.device.id,
      'startTime': unavailableStart?.toIso8601String(),
      'endTime': unavailableEnd?.toIso8601String(),
      'userId': currentUserId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Periode succesvol geblokkeerd')),
    );

    setState(() {
      unavailableStart = null;
      unavailableEnd = null;
    });
    fetchDeviceReservations();
  }
  bool isReserved(DateTime day) {
    for (var r in allReservations) {
      if (!day.isBefore(r.startTime) && !day.isAfter(r.endTime)) {
        return true;
      }
    }
    return false;
  }
    void onDayTapped(DateTime day) {
    if(isReserved(day)) return;
    setState(() {
      focusedDay=day;
      if (unavailableStart == null || (unavailableStart != null && unavailableEnd != null)) {
        unavailableStart = day;
        unavailableEnd = null;
      } else {
        bool conflict=false;
        DateTime cursor = unavailableStart!;
        while(!cursor.isAfter(day)) {
          if(isReserved(cursor)) {
            conflict=true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Selectie overlapt met een bestaande reservatie!"))
            );
            break;
          }
          cursor = cursor.add(Duration(days: 1));
        }
        if(day.isBefore(unavailableStart!)) {
          conflict=true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selecteer een datum die na de begindatum komt!"))
          );
        }
        if(!conflict) {
          unavailableEnd = day;
        }
      }
    });
  }
  Future<void> deleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apparaat verwijderen?'),
        content: const Text('Weet je zeker dat je dit apparaat wil verwijderen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen')),
        ],
      ),
    );

    if (confirm == true) {
      final firestore = FirebaseFirestore.instance;

      final querySnapshot = await firestore
          .collection('reservations')
          .where('deviceId', isEqualTo: widget.device.id)
          .get();

      final batch = firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      final deviceRef = firestore.collection('devices').doc(widget.device.id);
      batch.delete(deviceRef);

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeScreen()));
      }
    }
  }
  Future<void> deleteReservation(String id) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reservatie verwijderen?'),
      content: const Text('Weet je zeker dat je deze reservatie wil verwijderen?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen')),
      ],
    ),
  );
  print(id);
  if (confirm == true) {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservatie verwijderd')),
    );
  }
    setState(() {
      fetchDeviceReservations();
    });
  }
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'nl_NL');

    return Scaffold(
      appBar: AppBar(
        title: Text('Verhuurder beheer: ${widget.device.name}'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reservaties voor dit apparaat:', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (reservations.isEmpty)
                    const Text('Geen reservaties gevonden.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        final r = reservations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              '${dateFormat.format(r.startTime)} - ${dateFormat.format(r.endTime)}',
                            ),
                            subtitle: Text('Gebruiker ID: ${r.userId}'),
                            trailing: IconButton(
                              onPressed: () => deleteReservation(r.id), 
                              icon: Icon(Icons.delete, color: Colors.red,)
                            ),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 32),

                  Text('Periode blokkeren:', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  TableCalendar(
                    locale: "nl_NL",
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(Duration(days: 365)),
                    focusedDay: focusedDay,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month'
                    },
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) {
                      if (unavailableStart == null) return false;
                      if (unavailableEnd == null) return day == unavailableStart;
                      return !day.isBefore(unavailableStart!) && !day.isAfter(unavailableEnd!);
                    },
                    onDaySelected: (selectedDay, _) => onDayTapped(selectedDay),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final reserved = isReserved(day);
                        final isInRange = unavailableStart != null &&
                            unavailableEnd != null &&
                            !day.isBefore(unavailableStart!) &&
                            !day.isAfter(unavailableStart!);

                        if (reserved) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.red[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: TextStyle(color: Colors.white)),
                          );
                        }

                        if (isInRange) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: TextStyle(color: Colors.white)),
                          );
                        }

                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final reserved = isReserved(day);
                        final isInRange = unavailableStart != null &&
                            unavailableEnd != null &&
                            !day.isBefore(unavailableStart!) &&
                            !day.isAfter(unavailableEnd!);

                        if (reserved) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        }

                        if (isInRange) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: (unavailableStart != null && unavailableEnd != null) ? blockDevicePeriod : null,
                    child: const Text('Blokkeren'),
                  ),

                  const Divider(height: 32),

                  ElevatedButton.icon(
                    onPressed: deleteDevice,
                    icon: const Icon(Icons.delete),
                    label: const Text('Apparaat verwijderen', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, iconColor: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
