import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AddSpendPage extends StatefulWidget {

  final String name; // Variable to store the user's name
  //final String monthlyIncome; // Variable to store the user's monthly income

  const AddSpendPage({
    Key? key,
    required this.name,
    //required this.monthlyIncome,
  }) : super(key: key);


  @override
  _AddSpendPageState createState() => _AddSpendPageState();
}

class _AddSpendPageState extends State<AddSpendPage> {
  int amount = 0; // Initial amount
  final TextEditingController _controller = TextEditingController();

  // List of spending categories
  String selectedCategory = 'Travel'; // Default value for the dropdown
  List<String> spendCategories = ['Travel', 'Food', 'Rent', 'Light Bill', 'EMI', 'Other'];

  bool _showOtherField = false; // Boolean to control the visibility of the "Other" field

  void _incrementAmount() {
    setState(() {
      amount++;
      _controller.text = amount.toString(); // Update text field
    });
  }

  void _decrementAmount() {
    setState(() {
      if (amount > 0) {
        amount--;
        _controller.text = amount.toString(); // Update text field
      }
    });
  }

  Future<void> _addSpend() async {
    // Gather the data to send
    //String place = _placeController.text;
    //String category = _showOtherField ? _otherController.text : selectedCategory;
    String username = widget.name; // Replace with actual username if dynamic

    // Create the payload
    Map<String, dynamic> payload = {
      'username': username+"@gmail.com",
      'spendAmt': amount.toString(),
      //'place': place,
      //'category': category,
    };

    // Send POST request
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/add-spend'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload), // Convert payload to JSON string
      );

      if (response.statusCode == 200) {
        // Spend added successfully
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Spend added successfully.'),
          backgroundColor: Colors.green,
        ));
      } else {
        // Error adding spend
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error adding spend.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // Handle any errors that occur during the request
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to connect to the server.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        title: const Text(
          'Add Spend',
          style: TextStyle(
            color: Colors.deepOrange,
            fontSize: 34.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
          children: [
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
                        children: const [
                          Icon(
                            Icons.currency_rupee,
                            color: Colors.green,
                            size: 34,
                          ),
                          Text(
                            '10000', // Replace this with the dynamic value
                            style: TextStyle(
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
            const SizedBox(height: 40.0), // Space between card and other widgets
            const Text(
              'Add Money', // Label for the increment/decrement field
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0), // Space between label and input field
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.deepOrange),
                  onPressed: _decrementAmount, // Decrement button
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white, // White background for the text field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none, // No border
                      ),
                      hintText: 'Enter amount',
                    ),
                    onChanged: (value) {
                      // Update amount based on user input
                      if (value.isNotEmpty) {
                        amount = int.tryParse(value) ?? 0; // Parse the input to an integer
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                  onPressed: _incrementAmount, // Increment button
                ),
              ],
            ),
            const SizedBox(height: 40.0), // Space between card and other widgets
            const Text(
              'Where Spend?', // Label for the dropdown
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0), // Space between label and dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // Padding inside the dropdown container
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true, // Makes the dropdown take the full width
                  value: selectedCategory, // Initial dropdown value
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      _showOtherField = selectedCategory == 'Other'; // Show or hide the "Other" field
                    });
                  },
                  items: spendCategories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40.0),

            // Animated transition for the "Other" input field
            AnimatedOpacity(
              opacity: _showOtherField ? 1.0 : 0.0, // Fade in or out
              duration: const Duration(milliseconds: 500), // Animation duration
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500), // Animation duration for size change
                height: _showOtherField ? 60.0 : 0.0, // Animate height based on visibility
                child: _showOtherField
                    ? TextField(
                        decoration: InputDecoration(
                          labelText: 'Other',
                          labelStyle: const TextStyle(color: Color.fromARGB(137, 0, 0, 0)),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.deepOrange), // Deep orange border
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.money_off, color: Colors.deepOrange), // Money icon
                        ),
                        keyboardType: TextInputType.text,
                      )
                    : const SizedBox(), // Empty box when hidden
              ),
            ),

            const SizedBox(height: 40.0),
            Center( // Center the button
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 280, // Increase button width
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Add Spend click
                      _addSpend();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Rounded corners
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: Text(
                        'Add Spend',
                        style: TextStyle(
                          color: Colors.white, // White text
                          fontSize: 18, // Text size
                        ),
                      ),
                    ),
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
