import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the LoginPage
import 'signup_page.dart'; // Import the SignupPage

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/intro_img.png'), // Ensure correct image path
                fit: BoxFit.cover, // Ensures the image covers the entire screen
              ),
            ),
          ),
          // Sign Up Text and Buttons
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Centers vertically
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Margin on top for Sign Up text
                const Padding(
                  padding: EdgeInsets.only(top: 380), // Adjust the margin-top value as needed
                  child: Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 40, // Large font size
                      color: Colors.black, // Black color text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 25), // Space between Sign Up and Sign In button
                
                // Sign In Button with adjustable width and transparent background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 280, // Increased button width
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Sign In click
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Transparent background
                        side: const BorderSide(color: Colors.black), // Black border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.black, // Black text
                            fontSize: 18, // Text size
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 37), // Space between Sign In and Continue with Mail button

                // Continue with Mail Button with adjustable width and transparent background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 280, // Increased button width
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Continue with Mail click
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Transparent background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.5, horizontal: 20.0), // Added left padding
                        child: Text(
                          'Continue with Mail',
                          style: TextStyle(
                            color: Colors.white, // White text
                            fontSize: 16, // Text size
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50), // Space at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }
}
