import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For encoding/decoding JSON
import 'dashboard_page.dart'; // Import the DashboardPage
import 'login_page.dart'; // Import the LoginPage

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController incomeController = TextEditingController();

    void _showErrorDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    Future<void> _registerUser() async {
      final url = Uri.parse('http://192.168.31.230:8080/api/register');
      final headers = {'Content-Type': 'application/json'};

      // Create a user data object to send to the backend
      final Map<String, String> body = {
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'income': incomeController.text,
        "spend":"0"
      };

      try {
        final response = await http.post(url, headers: headers, body: json.encode(body));

        if (response.statusCode == 201) {
          // Registration successful, navigate to dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                name: nameController.text, // Passing the name to the dashboard
              ),
            ),
          );
        } else {
          // Handle error (e.g., email already exists)
          final message = response.body;
          _showErrorDialog(context, message);
        }
      } catch (e) {
        print('Error registering user: $e');
        _showErrorDialog(context, 'Error registering user.');
      }
    }



    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/signup_img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Input fields and Buttons
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 250), // Top margin for fields
                  // Name Input Field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.person, color: Colors.deepOrange),
                    ),
                  ),
                  const SizedBox(height: 25), // Space between Name and Email fields
                  // Email Input Field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.email, color: Colors.deepOrange),
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
                        borderSide: const BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.lock, color: Colors.deepOrange),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 25), // Space between Password and Income fields
                  // Monthly Income Input Field
                  TextField(
                    controller: incomeController,
                    decoration: InputDecoration(
                      labelText: 'Monthly Income',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.attach_money, color: Colors.deepOrange),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 37), // Space between fields and buttons
                  // Sign Up Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      width: 280,
                      child: ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Signup',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Space between button and text
                  const Text(
                    'Already Registered?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 0), // Space between texts
                  GestureDetector(
                    onTap: () {
                      // Navigate to Login Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login here',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
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
