import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart'; // Import DashboardPage to navigate back

class AddSpendPage extends StatefulWidget {
  final String name;
  final double remainingBalance;

  const AddSpendPage({
    Key? key,
    required this.name,
    required this.remainingBalance,
  }) : super(key: key);

  @override
  _AddSpendPageState createState() => _AddSpendPageState();
}

class _AddSpendPageState extends State<AddSpendPage> {
  int amount = 0;
  final TextEditingController _controller = TextEditingController();
  String selectedCategory = 'Travel';
  List<String> spendCategories = ['Travel', 'Food', 'Rent', 'Light Bill', 'EMI', 'Other'];
  bool _showOtherField = false;

  void _incrementAmount() {
    setState(() {
      amount++;
      _controller.text = amount.toString();
    });
  }

  void _decrementAmount() {
    setState(() {
      if (amount > 0) {
        amount--;
        _controller.text = amount.toString();
      }
    });
  }

  Future<void> _addSpend() async {
    String username = widget.name;

    Map<String, dynamic> payload = {
      'username': "$username@gmail.com",
      'spendAmt': amount.toString(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.230:8080/api/add-spend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Spend added successfully.'),
          backgroundColor: Colors.green,
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage(name: widget.name)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error adding spend.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
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
        automaticallyImplyLeading: false,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remaining Balance Card
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
                            widget.remainingBalance.toString(), // Use the passed value correctly
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
            const SizedBox(height: 40.0),
            const Text(
              'Add Money',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            // Add Money Field
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.deepOrange),
                  onPressed: _decrementAmount,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Enter amount',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        amount = int.tryParse(value) ?? 0;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                  onPressed: _incrementAmount,
                ),
              ],
            ),
            const SizedBox(height: 40.0),
            const Text(
              'Where Spend?',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            // Spend Category Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.black, fontSize: 18.0),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      _showOtherField = selectedCategory == 'Other';
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
            // Other Category Field
            AnimatedOpacity(
              opacity: _showOtherField ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: _showOtherField ? 60.0 : 0.0,
                child: _showOtherField
                    ? TextField(
                        decoration: InputDecoration(
                          labelText: 'Other',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.money_off, color: Colors.deepOrange),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            const SizedBox(height: 40.0),
            // Add Spend Button
            Center(
              child: SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: _addSpend,
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
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
