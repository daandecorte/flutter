import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("User registered!");
    } catch (e) {
      print("Registration error: $e");
    }
  }

  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("User logged in!");
    } catch (e) {
      print("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login/Register")),
      body: Padding(
        padding: const EdgeInsets.only(top: 200, left: 200, right: 200),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            Row
            (
              mainAxisAlignment: MainAxisAlignment.center,
              children: 
              [
                ElevatedButton(onPressed: signUp, child: const Text("Register")),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: signIn, child: const Text("Login")),
              ]
            )
          ],
        ),
      ),
    );
  }
}