import 'package:flutter/material.dart';
import 'package:my_quran/screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Quran',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(primaryColor: Colors.cyanAccent),
      home: const HomeScreen(),
    );
  }
}
