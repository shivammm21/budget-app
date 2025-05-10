import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for HapticFeedback
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'addspend_page.dart';
import 'login_page.dart';
import 'split_page.dart'; // Import the login page for logout
import 'package:google_fonts/google_fonts.dart';

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

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  double totalSpend = 0;
  double remainingBalance = 0;
  double monthlyIncome = 15000.0; // Default monthly income
  List<Map<String, dynamic>> pendingPayments = []; // Initialize with empty list instead of using 'late'
  bool isLoading = true;
  late String name;
  late String category; // Add category as a property
  late int amount; // Add amount as a property
  late DateTime timestamp; // Add timestamp as a property
  int _selectedIndex = 0; // To keep track of the selected tab
  bool _showIncome = true; // Add this as a class property
  final TextEditingController _incomeController = TextEditingController();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // Confetti controller for celebrations
  late ConfettiController _confettiController;

  // Add these properties for offline functionality
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  bool _isOffline = false;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    name = widget.name;
    category = widget.category; // Initialize category
    amount = widget.amount; // Initialize amount
    timestamp = widget.timestamp; // Initialize timestamp
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize connectivity service
    _connectivityService.initialize();
    
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      setState(() {
        _isOffline = status == ConnectivityStatus.offline;
      });
      
      // If we're back online, attempt to sync
      if (status != ConnectivityStatus.offline) {
        _syncService.syncData();
        _fetchDashboardData(); // Try to fetch updated data from server
      }
    });
    
    // Listen for sync status updates
    _syncService.syncStatus.listen((status) {
      setState(() {
        _syncStatus = status;
      });
    });
    
    // Start periodic sync
    _syncService.startPeriodicSync();
    
    _fetchDashboardData();
    checkAndResetBalance();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _incomeController.dispose();
    _syncService.stopPeriodicSync();
    super.dispose();
  }
  
  Future<void> checkAndResetBalance() async {
  final prefs = await SharedPreferences.getInstance();
  int? lastMonthUpdated = prefs.getInt('lastMonthUpdated');
  int currentMonth = DateTime.now().month;

  // Check if it's a new month
  if (lastMonthUpdated != currentMonth) {
    // Update remaining balance to the monthly income
    setState(() {
      remainingBalance = monthlyIncome; // Set to the stored monthly income
    });

    // Store the current month as the last updated month
    prefs.setInt('lastMonthUpdated', currentMonth);
  }
}

  Future<void> _checkConnectivity() async {
    bool isOnline = await _connectivityService.checkConnectivity();
    setState(() {
      _isOffline = !isOnline;
    });
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (_connectivityService.isOnline) {
        // Online mode - fetch from server
        final url = Uri.parse('http://localhost:8080/api/dashboard/${widget.name}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
          
          // Update local database with fresh server data
          double serverMonthlyIncome = data['monthlyIncome'] != null ? double.parse(data['monthlyIncome']) : 15000.0;
          bool serverShowIncome = data['showIncome'] ?? true;
          await _dbHelper.saveUserSettings(widget.name, serverMonthlyIncome, serverShowIncome);
          
        setState(() {
            totalSpend = data['totalSpend'] != null ? double.parse(data['totalSpend']) : 0.0;
            remainingBalance = data['remainingBalance'] != null ? double.parse(data['remainingBalance']) : 0.0;
            monthlyIncome = serverMonthlyIncome;
          pendingPayments = List<Map<String, dynamic>>.from(data['pendingPayments'] ?? []);
            name = data['userName'] ?? widget.name;
            _showIncome = serverShowIncome;
          isLoading = false;
        });
      } else {
          // If server request fails, fall back to local data
          await _loadLocalData();
        }
      } else {
        // Offline mode - use local database
        await _loadLocalData();
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Fall back to local data on error
      await _loadLocalData();
    }
    
    // Start animations after data is loaded
    _animationController.forward();
  }
  
  // Load data from local database
  Future<void> _loadLocalData() async {
    try {
      double localTotalSpend = await _dbHelper.calculateTotalSpend(widget.name);
      Map<String, dynamic>? settings = await _dbHelper.getUserSettings(widget.name);
      
      double localMonthlyIncome = 15000.0;
      bool localShowIncome = true;
      
      if (settings != null) {
        localMonthlyIncome = settings['monthly_income'];
        localShowIncome = settings['show_income'] == 1;
      }
      
      double localRemainingBalance = localMonthlyIncome - localTotalSpend;
      
      // Get local transactions for history
      List<Map<String, dynamic>> localTransactions = await _dbHelper.getTransactions(widget.name);
      
      setState(() {
        totalSpend = localTotalSpend;
        remainingBalance = localRemainingBalance;
        monthlyIncome = localMonthlyIncome;
        _showIncome = localShowIncome;
        name = widget.name;
        pendingPayments = []; // Always initialize with empty list in offline mode
        historyData = localTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading local data: $e');
      setState(() {
        pendingPayments = []; // Make sure it's initialized even in case of error
        isLoading = false;
      });
    }
  }

  // Method to handle navigation between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        // Fetch history data when the History tab is selected
        _fetchHistoryData();
      }
    });
  }


  List<Map<String, dynamic>> historyData = [];

  Future<void> _fetchHistoryData() async {
    final url = Uri.parse('http://localhost:8080/api/dashboard/history/${widget.name}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          historyData = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load history data');
      }
    } catch (e) {
      print('Error fetching history data: $e');
      setState(() {
        historyData = []; // Initialize with empty list on error
      });
    }
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

Widget _buildPaymentCard(Map<String, dynamic> payment) {
  String category = payment['category'] as String? ?? 'Uncategorized';
  int amount = double.parse(payment['spendAmt']?.toString() ?? '0').round();
  String payerUser = payment['payeruser'] as String? ?? 'Unknown';
  String place = payment['place'] as String? ?? 'Unknown';

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    child: Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.pending_actions, color: Colors.deepOrange, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pending Payment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Call backend to mark as settled
                    final response = await http.post(
                      Uri.parse('http://localhost:8080/api/pay-split'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'username': name, // current user
                        'payerName': payerUser,
                        'category': category,
                        'place': place,
                        'spendAmt': amount,
                      }),
                    );
                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Payment settled!'),
                        backgroundColor: Colors.green,
                      ));
                      _fetchDashboardData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to settle payment.'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                  label: const Text('Settle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.category, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                Icon(Icons.place, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  place,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payer: $payerUser',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                const Spacer(),
                Icon(Icons.currency_rupee, color: Colors.green, size: 20),
                const SizedBox(width: 4),
                Text(
                  '₹$amount',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}



  // Define the different bodies for each tab
  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_poqmycwy.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading your finances...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.topCenter,
              children: [
                // Main content
                SingleChildScrollView(
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
          child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                          // Show offline banner if needed
                          if (_isOffline)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cloud_off, color: Colors.orange),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'You\'re offline',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        Text(
                                          'Your changes will sync when you reconnect',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Total Spend with animated container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                    width: double.infinity,
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
                      padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                              'Total Spent',
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                ),
                              const SizedBox(width: 12),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: totalSpend),
                                duration: const Duration(seconds: 1),
                                builder: (context, value, child) {
                                  return Text(
                                    value.toStringAsFixed(2),
                                    style: GoogleFonts.poppins(
                                    color: Colors.red,
                                      fontSize: 32.0,
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
                  const SizedBox(height: 16.0),
                          // Remaining Balance - only show if _showIncome is true
                          if (_showIncome)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
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
                    child: Stack(
                      children: [
                        if (remainingBalance < 0)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                              child: Text(
                                'OVERSPENT',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
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
                            const SizedBox(height: 10),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: remainingBalance >= 0
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                  Icons.currency_rupee,
                                      color: remainingBalance >= 0 ? Colors.green : Colors.red,
                                      size: 30,
                                ),
                                  ),
                                  const SizedBox(width: 12),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: remainingBalance),
                                    duration: const Duration(seconds: 1),
                                    builder: (context, value, child) {
                                      // Format the value to handle negative numbers properly
                                      String formattedValue = value < 0 
                                          ? value.abs().toStringAsFixed(2)
                                          : value.toStringAsFixed(2);
                                      
                                      return RichText(
                                        text: TextSpan(
                                          children: [
                                            if (value < 0)
                                              TextSpan(
                                                text: "-",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                  fontSize: 32.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            TextSpan(
                                              text: formattedValue,
                                              style: GoogleFonts.poppins(
                                                color: value < 0 ? Colors.red : Colors.green,
                                                fontSize: 32.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (remainingBalance < 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                Text(
                                        'You have spent more than your budget',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0), // Spacing between cards
                  Container(
                    margin: const EdgeInsets.only(left: 16.0), // Add left margin
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pending Payment',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0, // Same font size as 'Remaining' text
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 10),
                pendingPayments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No pending payments'),
                      )
                    : Column(
                        children: pendingPayments.map((payment) {
                          return _buildPaymentCard(payment);
                        }).toList(),
                      ),
                  const SizedBox(height: 20),
                          
                          // Add Spend Button with Animation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: 280,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                        AddSpendPage(
                                          name: widget.name, 
                                          remainingBalance: remainingBalance,
                                          showIncome: _showIncome,
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                                  elevation: 5,
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
                  const SizedBox(height: 20),
                          
                          // Smart Split Button with Animation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: 280,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                        SplitPage(
                                          name: widget.name, 
                                          remainingBalance: remainingBalance,
                                          showIncome: _showIncome,
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 34, 174, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                                  elevation: 5,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Smart Split',
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
                    ),
                  ),
                ),
                
                // Confetti overlay
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    particleDrag: 0.05,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.2,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple
                    ],
                  ),
                ),
              ],
          );
    } else if (_selectedIndex == 1) {
      if (historyData.isEmpty && !_isOffline) {
        // Fetch the history data only if it's not already fetched and online
        _fetchHistoryData();
      } else if (historyData.isEmpty && _isOffline) {
        // In offline mode, get history from local database
        _loadLocalData();
      }
      return Container(
        color: Colors.grey[50],
            child: Column(
          children: [
            // Offline banner if needed (but without the duplicate header)
            if (_isOffline)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Showing offline transaction history',
                        style: GoogleFonts.poppins(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                ),
                  ],
                ),
              ),
            
            // Expanded list of transactions
            Expanded(
              child: historyData.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.network(
                          'https://assets7.lottiefiles.com/packages/lf20_VrYnXA.json',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No transactions yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your transaction history will appear here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: historyData.length,
                    itemBuilder: (context, index) {
                      // Extract transaction data
                      final transaction = historyData[index];
                      String category = transaction['category'] ?? 'Uncategorized';
                      double amount = double.tryParse(transaction['spendAmt']?.toString() ?? '0') ?? 0;
                      
                      // Parse timestamp
                      DateTime timestamp = transaction['created_at'] != null 
                        ? DateTime.parse(transaction['created_at']) 
                        : DateTime.now();
                        
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                  color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // Could add transaction details view here
                              HapticFeedback.lightImpact();
                            },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(category).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(category),
                                              color: _getCategoryColor(category),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                            Text(
                              category,
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                            ),
                            Text(
                                        '-₹${amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                                  const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                        '${_formatDate(timestamp)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                            ),
                            Text(
                                        '${_formatTime(timestamp)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                            ),
                          ],
                        ),
                      ],
                              ),
                            ),
                    ),
                  ),
                );
                    },
            ),
          ),
          ],
        ),
      );
    }
    else {
      // Profile Tab with Animation and Sync Status
      return Scaffold(
        body: SingleChildScrollView(
        child: Container(
  color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
    child: Column(
      children: [
                // User Greeting Animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.1, 0.5, curve: Curves.easeOut),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Lottie.network(
                          'https://assets4.lottiefiles.com/packages/lf20_touohxv0.json',
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Welcome, $name!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Managing your finances like a pro!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Show sync status card if offline
                if (_isOffline || _syncStatus.isNotEmpty)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(0.2, 0.6, curve: Curves.easeOut),
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isOffline ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isOffline ? Icons.cloud_off : Icons.cloud_sync,
                                color: _isOffline ? Colors.orange : Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isOffline ? 'Offline Mode' : 'Sync Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isOffline ? Colors.orange : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _syncStatus.isNotEmpty ? _syncStatus : (_isOffline 
                              ? 'Your changes will sync when you reconnect'
                              : 'All changes are synced'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_isOffline)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _checkConnectivity();
                                  if (!_isOffline) {
                                    _syncService.syncData();
                                    _fetchDashboardData();
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Check Connection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                
                // Income Display Toggle with Animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                  )),
                  child: Card(
                    color: Colors.white,
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Income Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Show Remaining Income',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              Switch(
                                value: _showIncome,
                                onChanged: (value) {
                                  _toggleIncomeDisplay(value);
                                },
                                activeColor: Colors.deepOrange,
                              ),
                            ],
                          ),
                          if (_showIncome) ...[
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Monthly Income:',
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.currency_rupee,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    Text(
                                      '${monthlyIncome.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showMonthlyIncomeDialog(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Add a manual sync button
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.4, 0.8, curve: Curves.easeOut),
                  )),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 30),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_connectivityService.isOnline) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Syncing data...'),
                            backgroundColor: Colors.blue,
                          ));
                          await _syncService.syncData();
                          await _fetchDashboardData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Sync completed'),
                            backgroundColor: Colors.green,
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('You\'re offline. Cannot sync now.'),
                            backgroundColor: Colors.orange,
                          ));
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                  ),
                ),
                
                // Logout Button with Animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.5, 0.9, curve: Curves.easeOut),
                  )),
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
            onPressed: () {
                        _showLogoutConfirmationDialog(context);
            },
            style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 235, 70, 70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
                        elevation: 8,
            ),
            icon: const Icon(
                        Icons.logout,
              color: Colors.white,
                        size: 24,
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
        ),
      ],
    ),
  ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
            children: [
                      Text(
                'Hello,',
                        style: GoogleFonts.poppins(
                  color: Colors.deepOrange,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                name,
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade700,
                          fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOffline 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done, 
                          color: _isOffline ? Colors.orange : Colors.green, 
                          size: 16
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isOffline ? 'Offline' : 'Online',
                          style: GoogleFonts.poppins(
                            color: _isOffline ? Colors.orange : Colors.green,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  // Modified to work with both online/offline modes
  Future<void> _toggleIncomeDisplay(bool value) async {
    // If turning on income display, show dialog to enter monthly income
    if (value && !_showIncome) {
      _showMonthlyIncomeDialog(context);
      return;
    }
    
    // If just turning off, proceed with toggle
    setState(() {
      _showIncome = value;
    });
    
    try {
      // Save setting to local database first
      await _dbHelper.saveUserSettings(widget.name, monthlyIncome, value);
      
      // Try to update server if online
      if (_connectivityService.isOnline) {
        final url = Uri.parse('http://localhost:8080/api/toggle-income-display');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': widget.name,
            'showIncome': value,
          }),
        );
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Income display preference updated'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Server update pending - will sync when online'),
            backgroundColor: Colors.orange,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved offline - will sync when online'),
          backgroundColor: Colors.orange,
        ));
      }
      
      // Refresh dashboard data
      _fetchDashboardData();
    } catch (e) {
      print('Error updating income display preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error saving preference. Please try again.'),
        backgroundColor: Colors.red,
      ));
      
      // Reset to previous value
      setState(() {
        _showIncome = !value;
      });
    }
  }
  
  void _showMonthlyIncomeDialog(BuildContext context) {
    // Set the initial value in the text controller
    _incomeController.text = monthlyIncome.toString();
    
    showDialog(
      context: context,
      barrierDismissible: false, // User must respond to dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set Monthly Income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your monthly income to enable income tracking:'),
              const SizedBox(height: 20),
              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // User canceled, don't enable income tracking
                Navigator.of(dialogContext).pop();
                setState(() {
                  _showIncome = false; // Keep it disabled
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                double? income = double.tryParse(_incomeController.text);
                if (income == null || income <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                
                // Close dialog
                Navigator.of(dialogContext).pop();
                
                // Update monthly income and enable tracking
                await _updateMonthlyIncome(income);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateMonthlyIncome(double income) async {
    try {
      // Save to local database first
      await _dbHelper.saveUserSettings(widget.name, income, true);
      
      // If online, update server
      if (_connectivityService.isOnline) {
        // Update the income
        final incomeUrl = Uri.parse('http://localhost:8080/api/update-monthly-income');
        final incomeResponse = await http.post(
          incomeUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': widget.name,
            'monthlyIncome': income,
          }),
        );
        
        if (incomeResponse.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Server update pending - will sync when online'),
            backgroundColor: Colors.orange,
          ));
        }
        
        // Toggle the income display
        final toggleUrl = Uri.parse('http://localhost:8080/api/toggle-income-display');
        final toggleResponse = await http.post(
          toggleUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': widget.name,
            'showIncome': true,
          }),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved offline - will sync when online'),
          backgroundColor: Colors.orange,
        ));
      }
      
      setState(() {
        _showIncome = true;
        monthlyIncome = income;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Income tracking enabled'),
        backgroundColor: Colors.green,
      ));
      
      // Play celebration animation
      _showCelebration();
      
      // Refresh dashboard data
      _fetchDashboardData();
    } catch (e) {
      print('Error updating income settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error saving settings. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Method to show confetti animation
  void _showCelebration() {
    _confettiController.play();
  }

  // Add these helper methods for the history items

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'rent':
        return Icons.home;
      case 'light bill':
        return Icons.lightbulb;
      case 'emi':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return Colors.blue;
      case 'food':
        return Colors.orange;
      case 'rent':
        return Colors.purple;
      case 'light bill':
        return Colors.amber;
      case 'emi':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}



