import 'package:flutter/widgets.dart';

class RentingManagementScreen extends StatefulWidget{
  const RentingManagementScreen({super.key});

  @override
  State<RentingManagementScreen> createState() {
    return RentingManagementState();
  }
}
class RentingManagementState extends State<RentingManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return const Text("verhuurder beheer");
  }
}