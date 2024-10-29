import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart';

class SplitPage extends StatefulWidget {
  final String name;
  final double remainingBalance;

  const SplitPage({
    Key? key,
    required this.name,
    required this.remainingBalance,
  }) : super(key: key);

  @override
  _SplitPageState createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  int amount = 0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _splitCountController = TextEditingController();
  String selectedCategory = 'Travel';
  List<String> spendCategories = ['Travel', 'Food', 'Rent', 'Light Bill', 'EMI', 'Other'];
  bool _showOtherField = false;
  String otherCategory = '';
  String errorMessage = '';

  int splitCount = 0;
  List<TextEditingController> splitControllers = [];

  @override
  void dispose() {
    _amountController.dispose();
    _splitCountController.dispose();
    for (var controller in splitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _incrementAmount() {
    setState(() {
      amount++;
      _amountController.text = amount.toString();
    });
  }

  void _decrementAmount() {
    setState(() {
      if (amount > 0) {
        amount--;
        _amountController.text = amount.toString();
      }
    });
  }

  Future<void> _addSpend() async {
    String username = widget.name;

    if (amount <= 0) {
      setState(() {
        errorMessage = 'Please enter a valid amount.';
      });
      return;
    }

    if (selectedCategory == 'Other' && otherCategory.isEmpty) {
      setState(() {
        errorMessage = 'Please specify the other category.';
      });
      return;
    }

    Map<String, dynamic> payload = {
      'username': "$username@gmail.com",
      'spendAmt': amount.toString(),
      'category': selectedCategory == 'Other' ? otherCategory : selectedCategory,
      'timestamp': DateTime.now().toString(),
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
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              name: widget.name,
              amount: amount,
              category: selectedCategory == 'Other' ? otherCategory : selectedCategory,
              timestamp: DateTime.now(),
            ),
          ),
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

  void _updateSplitFields(int count) {
    setState(() {
      splitCount = count;
      splitControllers = List.generate(splitCount, (index) => TextEditingController());
    });
  }
  
  Future<void> _splitExpense() async {
    String payerUsername = "${widget.name}@gmail.com";
    double totalAmount = amount.toDouble();
    String place = "Restaurant"; // You can replace this with a field if needed
    String category = selectedCategory == 'Other' ? otherCategory : selectedCategory;

    // Collect participant usernames
    List<String> participants = splitControllers.map((controller) => controller.text.trim()).toList();

    // Validate participant usernames
    if (participants.isEmpty || participants.any((username) => username.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter valid participant usernames.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    Map<String, dynamic> payload = {
      'payerUsername': payerUsername,
      'totalAmount': totalAmount,
      'place': place,
      'category': category,
      'participants': participants,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.230:8080/api/split-expense'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Split expense added successfully.'),
          backgroundColor: Colors.green,
        ));
        // Optionally navigate back to a different page or clear inputs
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error adding split expense.'),
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
          'Smart Split',
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
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
                              widget.remainingBalance.toString(),
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
                      controller: _amountController,
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
                        if (!_showOtherField) otherCategory = '';
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
                          onChanged: (value) {
                            otherCategory = value;
                          },
                          decoration: InputDecoration(
                            labelText: 'Specify other',
                            labelStyle: const TextStyle(color: Color.fromARGB(137, 0, 0, 0)),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.deepOrange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.description, color: Colors.deepOrange),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 40.0),
              const Text(
                'Split',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              // Split Count Field
              TextField(
                controller: _splitCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter number of splits',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _updateSplitFields(int.tryParse(value) ?? 0);
                  }
                },
              ),
              const SizedBox(height: 10.0),
              Column(
                children: List.generate(splitCount, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextField(
                      controller: splitControllers[index],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter Username ${index + 1}',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _splitExpense,
          child: const Text(
            'Split',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}
