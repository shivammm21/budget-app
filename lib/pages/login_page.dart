import 'package:flutter/material.dart';
import 'signup_page.dart'; // Import the SignupPage
import 'dashboard_page.dart'; // Import the DashboardPage
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For jsonDecode

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    void _showErrorDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Login Failed"),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> _login() async {
      final String apiUrl = "http://192.168.31.230:8080/api/login";
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': emailController.text,
            'password': passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          // Extract the username part from the email (before the '@')
          String email = emailController.text;
          String username = email.split('@')[0]; // Extract username from email



          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(name: username),
            ),
          );
        } else if (response.statusCode == 404) {
          _showErrorDialog(context, "User not found");
        } else if (response.statusCode == 401) {
          _showErrorDialog(context, "Invalid email or password");
        } else {
          _showErrorDialog(context, "An error occurred. Please try again.");
        }
      } catch (e) {
        _showErrorDialog(context, "Failed to connect to server. Please try again later.");
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/login_img.png'), // Ensure correct image path
                fit: BoxFit.cover, // Ensures the image covers the entire screen
              ),
            ),
          ),
          // Input fields and Buttons
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Centers vertically
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 350), // Top margin for Email input field

                  // Email Input Field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color.fromARGB(137, 0, 0, 0)),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange), // Deep orange border
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.email, color: Colors.deepOrange), // Email icon
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 25), // Space between Email and Password fields

                  // Password Input Field
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange), // Deep orange border
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.lock, color: Colors.deepOrange), // Lock icon for password
                    ),
                    obscureText: true, // Hide password input
                  ),

                  const SizedBox(height: 37), // Space between Password field and buttons

                  // Login Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      width: 280, // Increase button width
                      child: ElevatedButton(
                        onPressed: _login, // Call the _login function on press
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white, // White text
                              fontSize: 18, // Text size
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // Space between button and text

                  // "Not have account?" text
                  const Text(
                    'Not have an account?',
                    style: TextStyle(
                      color: Colors.black, // Black text
                      fontSize: 16, // Text size
                    ),
                  ),

                  const SizedBox(height: 0), // Space between texts

                  // "Signup here" clickable text
                  GestureDetector(
                    onTap: () {
                      // Navigate to Signup Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      'Signup here',
                      style: TextStyle(
                        color: Colors.blue, // Blue clickable text
                        fontSize: 16, // Text size
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // Space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
