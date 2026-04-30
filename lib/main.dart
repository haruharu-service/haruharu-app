import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'auth_gate.dart';

void main() {
  ApiClient.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF151C38);
    const accent = Color(0xFF4B63FF);
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: background,
        ),
        scaffoldBackgroundColor: background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A314C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9DA6C8)),
          hintStyle: const TextStyle(color: Color(0xFF8B94B8)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
