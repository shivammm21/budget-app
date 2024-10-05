import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the LoginPage

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();

    // Delay for 3 seconds and then navigate to LoginPage
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/intro_img.gif'), // Ensure correct image path
                fit: BoxFit.cover, // Ensures the image covers the entire screen
              ),
            ),
          ),
        ],
      ),
    );
  }
}
