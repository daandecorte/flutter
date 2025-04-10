import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/screens/add-device-screen.dart';
import 'package:project/screens/auth-screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCxRTC962LHppzXcGKOhowN3MbdCUQxYEY",
      authDomain: "flutter-mobile-5437c.firebaseapp.com",
      projectId: "flutter-mobile-5437c",
      storageBucket: "flutter-mobile-5437c.firebasestorage.app",
      messagingSenderId: "423207358499",
      appId: "1:423207358499:web:b9aa135e7688e63c592196"
    ),
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Project',
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasData) {
          return AddDevice();
        }
        
        return AuthScreen();
      },
    );
  }
}