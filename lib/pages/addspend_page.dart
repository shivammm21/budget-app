import 'dart:convert';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'dashboard_page.dart';

class AddSpendPage extends StatefulWidget {
  final String name;
  final double remainingBalance;
  final bool showIncome;

  const AddSpendPage({
    Key? key,
    required this.name,
    required this.remainingBalance,
    this.showIncome = true,
  }) : super(key: key);

  @override
  _AddSpendPageState createState() => _AddSpendPageState();
}

class _AddSpendPageState extends State<AddSpendPage> with TickerProviderStateMixin {
  int amount = 0;
  final TextEditingController _controller = TextEditingController();
  String selectedCategory = 'Travel';
  String selectedPlace = 'Home';
  List<String> spendCategories = ['Travel', 'Food', 'Rent', 'Light Bill', 'EMI', 'Shopping', 'Other'];
  List<String> places = ['Home', 'Work', 'Restaurant', 'Shop', 'Online', 'Other'];
  bool _showOtherField = false;
  String otherCategory = '';
  String errorMessage = '';
  bool _isButtonPressed = false;
  bool _showQuickAmounts = false;
  List<int> quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _buttonController;
  late AnimationController _amountController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  
  // Confetti controller for celebrations
  late ConfettiController _confettiController;
  
  // Map of category icons
  final Map<String, IconData> categoryIcons = {
    'Travel': Icons.directions_car,
    'Food': Icons.restaurant,
    'Rent': Icons.home,
    'Light Bill': Icons.lightbulb,
    'EMI': Icons.account_balance,
    'Shopping': Icons.shopping_cart,
    'Other': Icons.more_horiz,
  };
  
  // Add these properties
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  bool _isOffline = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _amountController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Start animations
    _animationController.forward();
    
    // Check connectivity status
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      setState(() {
        _isOffline = status == ConnectivityStatus.offline;
      });
      
      // If we're back online, try to sync
      if (status != ConnectivityStatus.offline) {
        _syncService.syncData();
      }
    });
  }
  
  Future<void> _checkConnectivity() async {
    bool isOnline = await _connectivityService.checkConnectivity();
    setState(() {
      _isOffline = !isOnline;
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _amountController.dispose();
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _incrementAmount() {
    HapticFeedback.lightImpact();
    _amountController.reset();
    _amountController.forward();
    setState(() {
      amount++;
      _controller.text = amount.toString();
    });
  }

  void _decrementAmount() {
    if (amount > 0) {
      HapticFeedback.lightImpact();
      _amountController.reset();
      _amountController.forward();
    setState(() {
        amount--;
        _controller.text = amount.toString();
      });
    }
  }
  
  void _selectQuickAmount(int quickAmount) {
    HapticFeedback.mediumImpact();
    setState(() {
      amount = quickAmount;
      _controller.text = amount.toString();
      _showQuickAmounts = false;
    });
  }

  Future<void> _addSpend() async {
    // Button press animation
    _buttonController.reset();
    _buttonController.forward();
    HapticFeedback.mediumImpact();
    setState(() {
      _isButtonPressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _isButtonPressed = false;
    });
    String username = widget.name;
    // Validate inputs
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
    setState(() {
      errorMessage = '';
    });
    final categoryToSend = selectedCategory == 'Other' ? otherCategory : selectedCategory;
    Map<String, dynamic> transaction = {
      'username': username,
      'spendAmt': amount.toString(),
      'category': categoryToSend,
      'place': selectedPlace,
      'participants': [], // Always include this field
    };
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/add-spend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );
      if (response.statusCode == 200) {
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Spend added successfully!'),
          backgroundColor: Colors.green,
        ));
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              name: widget.name,
              amount: amount,
              category: categoryToSend,
              timestamp: DateTime.now(),
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Failed to add spend: [31m${response.body}[0m';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to add spend.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save transaction.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 1.0,
        title: Text(
          'Add Spend',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
            color: Colors.deepOrange,
              fontSize: 28.0,
            fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Add sync status indicator
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display error message if any
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                child: Text(
                  errorMessage,
                                    style: const TextStyle(color: Colors.red),
                ),
              ),
                              ],
                            ),
                          ),
                        ),
                        
                      // Remaining Balance Card - only show if showIncome is true
                      if (widget.showIncome)
                        Hero(
                          tag: 'remaining_balance',
                          child: SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.white,
                              elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                    Text(
                        'Remaining',
                                      style: GoogleFonts.nunito(
                                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                                        ),
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
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0, end: widget.remainingBalance),
                                          duration: const Duration(seconds: 1),
                                          curve: Curves.easeOutQuart,
                                          builder: (context, value, child) {
                                            Color textColor = value >= 0 ? Colors.green : Colors.red;
                                            return Text(
                                              value.toStringAsFixed(2),
                                              style: TextStyle(
                                                color: textColor,
                              fontSize: 34.0,
                                                fontWeight: FontWeight.bold,
                            ),
                                            );
                                          }
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
                        ),
                        
                      const SizedBox(height: 30.0),
                      
                      // Add Money section with interactive animations
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
              'Add Money',
                              style: GoogleFonts.nunito(
                                textStyle: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                                ),
              ),
            ),
            const SizedBox(height: 10.0),
                            
                            // Add Money Field with animation
                            AnimatedBuilder(
                              animation: _amountController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + _amountController.value * 0.05,
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
              children: [
                                    // Decrement button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: _decrementAmount,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Amount text field
                Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showQuickAmounts = !_showQuickAmounts;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.nunito(
                                              textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Enter amount',
                                              prefixIcon: const Icon(Icons.currency_rupee),
                                              suffixIcon: IconButton(
                                                icon: Icon(_showQuickAmounts ? Icons.expand_less : Icons.expand_more),
                                                onPressed: () {
                                                  setState(() {
                                                    _showQuickAmounts = !_showQuickAmounts;
                                                  });
                                                },
                                              ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                                                setState(() {
                        amount = int.tryParse(value) ?? 0;
                                                });
                      }
                    },
                  ),
                ),
                                      ),
                                    ),
                                    
                                    // Increment button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: _incrementAmount,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Quick amount suggestions
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: _showQuickAmounts ? 70 : 0,
                              curve: Curves.easeInOut,
                              child: _showQuickAmounts 
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: quickAmounts.map((quickAmount) {
                                          return GestureDetector(
                                            onTap: () => _selectQuickAmount(quickAmount),
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 10),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.grey.shade300),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue.withOpacity(0.05),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '₹${quickAmount.toString()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                ),
              ],
            ),
                      ),
                      
                      const SizedBox(height: 30.0),
                      
                      // Category Selection with visual icons
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(50 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
              'Where Spend?',
                              style: GoogleFonts.nunito(
                                textStyle: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
                            ),
                            const SizedBox(height: 15.0),
                            
                            // Category selection as interactive grid
            Container(
                              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
              ),
                              child: Column(
                                children: [
                                  // Show current selection
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          categoryIcons[selectedCategory] ?? Icons.category,
                                          color: Colors.deepOrange,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            selectedCategory,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 15),
                                  
                                  // Category grid
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: spendCategories.map((category) {
                                      bool isSelected = selectedCategory == category;
                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                    setState(() {
                                            selectedCategory = category;
                                            _showOtherField = category == 'Other';
                                            if (!_showOtherField) otherCategory = '';
                    });
                  },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: isSelected 
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.deepOrange.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                categoryIcons[category] ?? Icons.category,
                                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                    );
                  }).toList(),
                ),
                                ],
                              ),
                            ),
                          ],
              ),
            ),
                      
                      const SizedBox(height: 20.0),
                      
                      // Other Category Field with Animation
            AnimatedOpacity(
              opacity: _showOtherField ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: _showOtherField ? 60.0 : 0.0,
                          curve: Curves.easeInOut,
                child: _showOtherField
                    ? TextField(
                        onChanged: (value) {
                                    otherCategory = value;
                        },
                        decoration: InputDecoration(
                                    labelText: 'Specify other category',
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
                                    filled: true,
                                    fillColor: Colors.white,
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
                      
                      const SizedBox(height: 30.0),
                      
                      // Location selection
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(-50 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where did you spend?',
                              style: GoogleFonts.nunito(
                                textStyle: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedPlace,
                                  icon: const Icon(Icons.location_on),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.black, fontSize: 18.0),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedPlace = newValue;
                                      });
                                    }
                                  },
                                  items: places.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(value),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
            const SizedBox(height: 40.0),
                      
                      // Add Spend Button with Animation
                      AnimatedBuilder(
                        animation: _buttonController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _bounceAnimation.value,
                            child: child,
                          );
                        },
                        child: Center(
              child: SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: _addSpend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                                elevation: _isButtonPressed ? 2 : 8,
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                      'Add Spend',
                                    style: GoogleFonts.nunito(
                                      textStyle: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Confetti overlay for celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
          ],
        ),
      ),
        ],
      ),
    );
  }
}
