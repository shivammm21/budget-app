import 'package:flutter/material.dart';
import 'pages/intro_page.dart'; // Import your intro_page.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const IntroPage(), // Ensure `IntroPage` is constant if no internal state
    );
  }
}
