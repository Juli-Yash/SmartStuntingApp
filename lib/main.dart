// lib/main.dart
import 'package:flutter/material.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(
      child: CircularProgressIndicator(
        color: Colors.blue,
      ), // Warna biru untuk loading
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authService = AuthService();
    final token = await authService.getToken();

    setState(() {
      if (token != null) {
        _initialScreen = const HomeScreen();
      } else {
        _initialScreen = const LoginScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Stunting App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema utama biru
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // AppBar default biru
          foregroundColor: Colors.white, // Teks dan ikon AppBar putih
          elevation: 0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Tambahan input decoration theme untuk TextField agar lebih seragam
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade200, width: 1.0),
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(color: Colors.blue),
        ),
      ),
      home: _initialScreen,
    );
  }
}
