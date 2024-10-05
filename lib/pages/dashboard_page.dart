import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'addspend_page.dart';
import 'login_page.dart'; // Import the login page for logout

class DashboardPage extends StatefulWidget {
  final String name;
  final int amount;
  final String category;
  final DateTime timestamp;

  const DashboardPage({
    Key? key,
    required this.name,
    required this.amount,
    required this.category,
    required this.timestamp,
  }) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalSpend = 0;
  double remainingBalance = 0;
  bool isLoading = true;
  late String name;
  late String category; // Add category as a property
  late int amount; // Add amount as a property
  late DateTime timestamp; // Add timestamp as a property
  int _selectedIndex = 0; // To keep track of the selected tab

  @override
  void initState() {
    super.initState();
    name = widget.name;
    category = widget.category; // Initialize category
    amount = widget.amount; // Initialize amount
    timestamp = widget.timestamp; // Initialize timestamp
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final url = Uri.parse('http://192.168.31.230:8080/api/dashboard/${widget.name}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          totalSpend = double.parse(data['totalSpend']);
          remainingBalance = double.parse(data['remainingBalance']);
          name = data['userName'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Method to handle navigation between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index on tab change
    });
  }

  // Method to show the logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              // Set isLoggedIn to false in shared preferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              // Redirect to login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}


  // Define the different bodies for each tab
  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Total Spend
                  SizedBox(
                    width: double.infinity,
                    height: 150.0,
                    child: Card(
                      color: Colors.white,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  color: Colors.red,
                                  size: 34,
                                ),
                                Text(
                                  totalSpend.toString(),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 34.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Remaining Balance
                  SizedBox(
                    width: double.infinity,
                    height: 150.0,
                    child: Card(
                      color: Colors.white,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  color: Colors.green,
                                  size: 34,
                                ),
                                Text(
                                  remainingBalance.toString(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 34.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: 280,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddSpendPage(name: widget.name, remainingBalance: remainingBalance),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Add Spend',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
    } else if (_selectedIndex == 1) {
      
return Container(
  width: double.infinity,
  color: Colors.white, // Change background color to white
  child: SingleChildScrollView(
    child: Column(
      children: [
        // Month Card
        Card(
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Removed the month display
                const SizedBox(height: 10),
                Text(
                  'Category: $category',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Amount: ₹$amount',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Date: ${timestamp.day.toString().padLeft(2, '0')} ${_getMonthShort(timestamp.month)} ${timestamp.year}', // Formatted date without extra numbers
                  style: const TextStyle(fontSize: 16),
                ),
                // Row to align time to the right side of the card
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                  children: [
                    Text(
                      '${timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}', // Format time
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);


    } else {
      return Container(
  color: Colors.grey[200],
  padding: const EdgeInsets.symmetric(vertical: 120.0, horizontal: 20.0),
  child: Center(
    child: Column(
      children: [
        const SizedBox(height: 355), // Add top margin for the logout button
        SizedBox(
          width: 180, // Set the width to 180
          child: ElevatedButton.icon( // Use ElevatedButton.icon to add an icon
            onPressed: () {
              _showLogoutConfirmationDialog(context); // Show logout confirmation dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 235, 70, 70), // Light red background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
            ),
            icon: const Icon(
              Icons.logout, // Add logout icon
              color: Colors.white,
              size: 24, // Adjust icon size if necessary
            ),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1.0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Hello,',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex, // Current selected index
        onTap: _onItemTapped, // Handle tab change
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  String _getMonthShort(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
}



