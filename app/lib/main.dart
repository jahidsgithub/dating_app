import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DatingApp());
}

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString == null) return null;

    return jsonDecode(userString);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dating App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Arial",
        scaffoldBackgroundColor: const Color(0xfff6f7fb),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: getSavedUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
