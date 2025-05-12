import 'dart:convert';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_page.dart';

class SplitPage extends StatefulWidget {
  final String name;
  final double remainingBalance;
  final bool showIncome;

  const SplitPage({
    Key? key,
    required this.name,
    required this.remainingBalance,
    this.showIncome = true,
  }) : super(key: key);

  @override
  _SplitPageState createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> with SingleTickerProviderStateMixin {
  int amount = 0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _splitCountController = TextEditingController();
  String selectedCategory = 'Travel';
  List<String> spendCategories = ['Travel', 'Food', 'Rent', 'Light Bill', 'EMI', 'Other'];
  Map<String, IconData> categoryIcons = {
    'Travel': Icons.flight,
    'Food': Icons.restaurant,
    'Rent': Icons.home,
    'Light Bill': Icons.lightbulb,
    'EMI': Icons.credit_card,
    'Other': Icons.category,
  };
  bool _showOtherField = false;
  String otherCategory = '';
  String errorMessage = '';

  int splitCount = 0;
  List<TextEditingController> splitControllers = [];
  List<List<String>> userSuggestions = [];
  List<FocusNode> splitFocusNodes = [];
  List<bool> isPlus = [];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Confetti controller for celebrations
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _amountController.dispose();
    _splitCountController.dispose();
    for (var controller in splitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _incrementAmount() {
    setState(() {
      amount += 100;  // Increment by 100 for more practical use
      _amountController.text = amount.toString();
    });
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _decrementAmount() {
    setState(() {
      if (amount >= 100) {
        amount -= 100;  // Decrement by 100
        _amountController.text = amount.toString();
        // Add haptic feedback
        HapticFeedback.lightImpact();
      }
    });
  }

  void _updateSplitFields(int count) {
    setState(() {
      splitCount = count;
      splitControllers = List.generate(splitCount, (index) => TextEditingController());
      userSuggestions = List.generate(splitCount, (index) => []);
      splitFocusNodes = List.generate(splitCount, (index) => FocusNode());
      isPlus = List.generate(splitCount, (index) => true);
    });
  }
  
  Future<void> _splitExpense() async {
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
    
    if (splitCount <= 0) {
      setState(() {
        errorMessage = 'Please enter the number of people to split with.';
      });
      return;
    }

    // Collect participant usernames
    List<String> participants = splitControllers.map((controller) => controller.text.trim()).toList();

    // Validate participant usernames
    if (participants.any((username) => username.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter all participant usernames.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String payerUsername = "${widget.name}@gmail.com";
    double totalAmount = amount.toDouble();
    String place = "Restaurant"; // You can replace this with a field if needed
    String category = selectedCategory == 'Other' ? otherCategory : selectedCategory;

    Map<String, dynamic> payload = {
      'payerUsername': payerUsername,
      'totalAmount': totalAmount,
      'place': place,
      'category': category,
      'participants': participants,
    };

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_kkyiobqx.json',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Splitting expense...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final response = await http.post(
        Uri.parse('https://budget-app-server-p43q.onrender.com/api/split-expense'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Play celebration animation
        _confettiController.play();
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Split expense added successfully!'),
          backgroundColor: Colors.green,
        ));
        
        // Optional: Add a slight delay to show the celebration
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Navigate back to dashboard with animation
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              DashboardPage(
                name: widget.name,
                amount: amount,
                category: category,
                timestamp: DateTime.now(),
              ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error adding split expense.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // Close loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to connect to the server.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> fetchUserSuggestions(String query, int index) async {
    if (query.isEmpty) {
      setState(() {
        userSuggestions[index] = [];
      });
      return;
    }
    final isMobile = RegExp(r'^\d{10}\$').hasMatch(query);
    final url = isMobile
        ? Uri.parse('https://budget-app-server-p43q.onrender.com/api/user-suggestions?q=$query')
        : Uri.parse('https://budget-app-server-p43q.onrender.com/api/user-suggestions?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> suggestions = jsonDecode(response.body);
      setState(() {
        userSuggestions[index] = suggestions.cast<String>();
      });
    } else {
      setState(() {
        userSuggestions[index] = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Smart Split',
          style: GoogleFonts.poppins(
            color: Colors.deepOrange,
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              image: DecorationImage(
                image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
                opacity: 0.05,
                repeat: ImageRepeat.repeat,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: GoogleFonts.poppins(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Remaining Balance Card with better animation
                      if (widget.showIncome)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.currency_rupee,
                                        color: widget.remainingBalance >= 0 ? Colors.green : Colors.red,
                                        size: 34,
                                      ),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: widget.remainingBalance),
                                        duration: const Duration(seconds: 1),
                                        curve: Curves.easeOutQuart,
                                        builder: (context, value, child) {
                                          return Text(
                                            value.toStringAsFixed(2),
                                            style: GoogleFonts.poppins(
                                              color: widget.remainingBalance >= 0 ? Colors.green : Colors.red,
                                              fontSize: 36.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Amount Section with better design
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.1, 0.5, curve: Curves.easeOut),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Money',
                              style: GoogleFonts.poppins(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            
                            // Add Money Field with better design
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _decrementAmount,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(Icons.remove_circle, 
                                          color: Colors.deepOrange, 
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: InputBorder.none,
                                        hintText: 'Enter amount',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.grey.shade400,
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
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _incrementAmount,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(Icons.add_circle, 
                                          color: Colors.deepOrange, 
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Quick amount buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildQuickAmountButton(500),
                                  _buildQuickAmountButton(1000),
                                  _buildQuickAmountButton(2000),
                                  _buildQuickAmountButton(5000),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20.0),
                      
                      // Category Section with icon selection
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.2, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.2, 0.6, curve: Curves.easeOut),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where Spend?',
                              style: GoogleFonts.poppins(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            
                            // Category selector with icons
                            Container(
                              height: 110,
                              width: double.infinity,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: spendCategories.map((category) {
                                  return _buildCategoryItem(category);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Other Category Field with better animation
                      AnimatedOpacity(
                        opacity: _showOtherField ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: _showOtherField ? 70.0 : 0.0,
                          margin: _showOtherField ? const EdgeInsets.only(top: 16) : EdgeInsets.zero,
                          curve: Curves.easeInOut,
                          child: _showOtherField
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      otherCategory = value;
                                    },
                                    style: GoogleFonts.poppins(),
                                    decoration: InputDecoration(
                                      hintText: 'Specify other category',
                                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      prefixIcon: const Icon(Icons.category, color: Colors.deepOrange),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      
                      const SizedBox(height: 24.0),
                      
                      // Split Section with better design
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Split',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Equal Split',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Split Count Field with improved design
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.12),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.people, 
                                      color: Colors.deepOrange, 
                                      size: 24,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _splitCountController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: InputBorder.none,
                                        hintText: 'Enter number of splits',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          _updateSplitFields(int.tryParse(value) ?? 0);
                                          HapticFeedback.selectionClick();
                                        }
                                      },
                                    ),
                                  ),
                                  if (_splitCountController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        height: 30,
                                        width: 30,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20.0),
                      
                      // Participant Fields with better animation and design
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: List.generate(splitCount, (index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.12),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          TextField(
                                            controller: splitControllers[index],
                                            focusNode: splitFocusNodes[index],
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: InputBorder.none,
                                              hintText: 'Enter Username or Mobile',
                                              hintStyle: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (value) => fetchUserSuggestions(value, index),
                                          ),
                                          if (userSuggestions[index].isNotEmpty && splitFocusNodes[index].hasFocus)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              top: 60,
                                              child: Material(
                                                elevation: 2,
                                                borderRadius: BorderRadius.circular(8),
                                                child: ListView(
                                                  shrinkWrap: true,
                                                  children: userSuggestions[index].map((suggestion) {
                                                    return ListTile(
                                                      title: Text(suggestion),
                                                      onTap: () async {
                                                        setState(() {
                                                          // If suggestion is in the format 'Name (MobileNumber)', extract the mobile number
                                                          final match = RegExp(r'\((\d{10})\)').firstMatch(suggestion);
                                                          if (match != null) {
                                                            final mobile = match.group(1)!;
                                                            splitControllers[index].text = mobile;
                                                            // Call backend to get user ID/email for this mobile
                                                            fetchAndReplaceWithUserId(mobile, index);
                                                          } else {
                                                            splitControllers[index].text = suggestion;
                                                          }
                                                          userSuggestions[index] = [];
                                                        });
                                                        FocusScope.of(context).unfocus();
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: index == splitCount - 1 
                                        ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                                        : CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      // Add a little illustration when no splits
                      if (splitCount == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              children: [
                                Lottie.network(
                                  'https://assets5.lottiefiles.com/packages/lf20_ysrn2iwp.json',
                                  width: 150,
                                  height: 150,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Enter the number of people to split with',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
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
      bottomNavigationBar: Container(
        height: 90,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: ElevatedButton(
            onPressed: _splitExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.deepOrange.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.group_add,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  'Split Expenses',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method for quick amount buttons
  Widget _buildQuickAmountButton(int value) {
    return InkWell(
      onTap: () {
        setState(() {
          amount = value;
          _amountController.text = amount.toString();
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.deepOrange.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '₹$value',
          style: GoogleFonts.poppins(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  // Helper method to build category selection items
  Widget _buildCategoryItem(String category) {
    bool isSelected = selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          _showOtherField = category == 'Other';
          if (!_showOtherField) otherCategory = '';
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcons[category],
              color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.deepOrange : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to fetch and replace with user ID/email
  Future<void> fetchAndReplaceWithUserId(String mobile, int index) async {
    final url = Uri.parse('https://budget-app-server-p43q.onrender.com/api/user-id-by-mobile?mobile=$mobile');
    final response = await http.get(url);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      setState(() {
        splitControllers[index].text = response.body;
      });
    }
  }
}
