import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'connectivity_service.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Stream controllers for sync status
  final _syncStatusController = StreamController<String>.broadcast();
  Stream<String> get syncStatus => _syncStatusController.stream;
  
  // Sync in progress flag
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  // Auto sync timer
  Timer? _syncTimer;
  
  SyncService._internal() {
    // Initialize connectivity monitoring
    _connectivityService.initialize();
    
    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      if (status != ConnectivityStatus.offline) {
        // We got online, attempt sync
        syncData();
      }
    });
  }
  
  // Start periodic sync
  void startPeriodicSync({Duration period = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(period, (timer) {
      if (_connectivityService.isOnline) {
        syncData();
      }
    });
  }
  
  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sync data with server
  Future<bool> syncData() async {
    // Don't start a new sync if one is in progress
    if (_isSyncing) return false;
    
    // Check connectivity first
    if (!_connectivityService.isOnline) {
      _syncStatusController.add('Offline. Will sync when connection is available.');
      return false;
    }
    
    _isSyncing = true;
    _syncStatusController.add('Syncing data...');
    
    try {
      // Get pending transactions
      final pendingTransactions = await _dbHelper.getPendingTransactions();
      
      if (pendingTransactions.isEmpty) {
        _syncStatusController.add('No data to sync');
        _isSyncing = false;
        return true;
      }
      
      // Send transactions to server one by one
      int syncedCount = 0;
      for (var transaction in pendingTransactions) {
        // Remove local fields
        Map<String, dynamic> serverTransaction = Map.from(transaction);
        serverTransaction.remove('id');
        serverTransaction.remove('sync_status');
        serverTransaction.remove('created_at');
        
        // Send to server
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/add-spend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(serverTransaction),
        );
        
        if (response.statusCode == 200) {
          // Mark as synced
          await _dbHelper.markTransactionSynced(transaction['id']);
          syncedCount++;
        } else {
          // If server error, stop sync and retry later
          _syncStatusController.add('Sync error: ${response.body}');
          _isSyncing = false;
          return false;
        }
      }
      
      // Clear synced transactions
      await _dbHelper.clearSyncedTransactions();
      
      _syncStatusController.add('Synced $syncedCount transactions');
      _isSyncing = false;
      return true;
    } catch (e) {
      _syncStatusController.add('Sync failed: $e');
      _isSyncing = false;
      return false;
    }
  }
  
  // Sync user settings (bidirectional)
  Future<bool> syncUserSettings(String username) async {
    if (!_connectivityService.isOnline) return false;
    
    try {
      // Send local settings to server
      final localSettings = await _dbHelper.getUserSettings(username);
      if (localSettings != null) {
        await http.post(
          Uri.parse('http://localhost:8080/api/update-monthly-income'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'monthlyIncome': localSettings['monthly_income'],
          }),
        );
        
        await http.post(
          Uri.parse('http://localhost:8080/api/toggle-income-display'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'showIncome': localSettings['show_income'] == 1,
          }),
        );
      }
      
      // Get settings from server
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/dashboard/$username'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        double monthlyIncome = data['monthlyIncome'] != null ? double.parse(data['monthlyIncome']) : 15000.0;
        bool showIncome = data['showIncome'] ?? true;
        
        // Update local settings
        await _dbHelper.saveUserSettings(username, monthlyIncome, showIncome);
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing user settings: $e');
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _syncStatusController.close();
    _syncTimer?.cancel();
  }
} 