import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/device.dart';
import 'package:project/models/reservation.dart';
import 'package:table_calendar/table_calendar.dart';

class ReserveDeviceScreen extends StatefulWidget {
  final Device device;

  const ReserveDeviceScreen({required this.device});

  @override
  _ReserveDeviceScreenState createState() => _ReserveDeviceScreenState();
}

class _ReserveDeviceScreenState extends State<ReserveDeviceScreen> {
  List<Reservation> reservations = [];
  DateTime? selectedStart;
  DateTime? selectedEnd;
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadReservations();
  }

  Future<void> loadReservations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: widget.device.id)
        .get();

    setState(() {
      reservations = snapshot.docs.map((doc) {
        return Reservation.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  bool isReserved(DateTime day) {
    for (var r in reservations) {
      if (!day.isBefore(r.startTime) && !day.isAfter(r.endTime)) {
        return true;
      }
    }
    return false;
  }

  bool rangeHasConflict(DateTime start, DateTime end) {
    for (var r in reservations) {
      if (start.isBefore(r.endTime) && end.isAfter(r.startTime)) {
        return true;
      }
    }
    return false;
  }

  void onDayTapped(DateTime day) {
    if(isReserved(day)) return;
    setState(() {
      focusedDay=day;
      if (selectedStart == null || (selectedStart != null && selectedEnd != null)) {
        selectedStart = day;
        selectedEnd = null;
      } else {
        bool conflict=false;
        DateTime cursor = selectedStart!;
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
        if(day.isBefore(selectedStart!)) {
          conflict=true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selecteer een datum die na de begindatum komt!"))
          );
        }
        if(!conflict) {
          selectedEnd = day;
        }
      }
    });
  }

  Future<void> confirmReservation() async {
    if (selectedStart == null || selectedEnd == null) return;
    if (rangeHasConflict(selectedStart!, selectedEnd!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selectie overlapt met reeds gereserveerde reservaties!")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reservation = Reservation(
      id: '',
      deviceId: widget.device.id,
      userId: user.uid,
      startTime: selectedStart!,
      endTime: selectedEnd!,
    );

    await FirebaseFirestore.instance
        .collection('reservations')
        .add(reservation.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reservatie bevestigd")),
    );

    setState(() {
      selectedStart = null;
      selectedEnd = null;
    });

    await loadReservations();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reserveer Apparaat: ${widget.device.name}, €${widget.device.price}/Dag')),
      body: Column(
        children: [
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
              if (selectedStart == null) return false;
              if (selectedEnd == null) return day == selectedStart;
              return !day.isBefore(selectedStart!) && !day.isAfter(selectedEnd!);
            },
            onDaySelected: (selectedDay, _) => onDayTapped(selectedDay),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final reserved = isReserved(day);
                final isInRange = selectedStart != null &&
                    selectedEnd != null &&
                    !day.isBefore(selectedStart!) &&
                    !day.isAfter(selectedEnd!);

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
                final isInRange = selectedStart != null &&
                    selectedEnd != null &&
                    !day.isBefore(selectedStart!) &&
                    !day.isAfter(selectedEnd!);

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
          const SizedBox(height: 20),
          reservationSummary(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (selectedStart != null && selectedEnd != null)
                ? confirmReservation
                : null,
            child: Text('Bevestig Reservatie'),
          ),
        ],
      ),
    );
  }
  Widget reservationSummary() {
    if(selectedStart==null||selectedEnd==null) {
      return SizedBox();
    }
    final days = selectedEnd!.difference(selectedStart!).inDays+1;
    final totalPrice = days*widget.device.price;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Geselecteerde periode:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "${DateFormat('dd MMM yyyy', 'nl').format(selectedStart!)} – ${DateFormat('dd MMM yyyy', 'nl').format(selectedEnd!)}",
        ),
        SizedBox(height: 6),
        Text(
          "Totaalprijs: €${totalPrice.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
    );
  }
}
