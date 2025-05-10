import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static SharedPreferences? _prefs;
  final _lock = Lock();
  final String _prefKeyTransactions = 'local_transactions';
  final String _prefKeyPendingTransactions = 'pending_transactions';
  final String _prefKeyUserSettings = 'user_settings';

  // Singleton pattern
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    } else {
      await database;
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web platform');
    }
    
    if (_database != null) return _database!;
    
    // Initialize the database if it doesn't exist
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web platform');
    }
    
    // Get the directory for storing the database file
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'budget.db');
    
    // Open/create the database
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create tables for offline storage
    await db.execute('''
      CREATE TABLE pending_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        spendAmt TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        place TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        spendAmt TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL, 
        place TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_settings(
        username TEXT PRIMARY KEY,
        monthly_income REAL NOT NULL DEFAULT 15000.0,
        show_income INTEGER NOT NULL DEFAULT 1,
        last_sync TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Add a new transaction to local storage
  Future<int> addTransaction(Map<String, dynamic> transaction) async {
    if (kIsWeb) {
      return await _addTransactionWeb(transaction);
    } else {
      return await _addTransactionMobile(transaction);
    }
  }
  
  // Mobile implementation using SQLite
  Future<int> _addTransactionMobile(Map<String, dynamic> transaction) async {
    Database db = await database;
    
    // Make a copy to add the sync status
    Map<String, dynamic> pendingTransaction = Map.from(transaction);
    pendingTransaction['sync_status'] = 0; // 0 = Not synced
    
    // Add to both tables - pending for sync and regular for display
    int pendingId = await db.insert('pending_transactions', pendingTransaction);
    await db.insert('transactions', transaction);
    
    return pendingId;
  }
  
  // Web implementation using SharedPreferences
  Future<int> _addTransactionWeb(Map<String, dynamic> transaction) async {
    // Add to transactions list
    List<String> transactions = _prefs?.getStringList(_prefKeyTransactions) ?? [];
    Map<String, dynamic> transactionWithId = Map.from(transaction);
    
    // Generate a simple ID
    transactionWithId['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    transactionWithId['created_at'] = DateTime.now().toIso8601String();
    
    transactions.add(jsonEncode(transactionWithId));
    await _prefs?.setStringList(_prefKeyTransactions, transactions);
    
    // Add to pending transactions list
    List<String> pendingTransactions = _prefs?.getStringList(_prefKeyPendingTransactions) ?? [];
    Map<String, dynamic> pendingTransaction = Map.from(transactionWithId);
    pendingTransaction['sync_status'] = 0; // 0 = Not synced
    
    pendingTransactions.add(jsonEncode(pendingTransaction));
    await _prefs?.setStringList(_prefKeyPendingTransactions, pendingTransactions);
    
    return pendingTransactions.length;
  }
  
  // Get all locally stored transactions for a user
  Future<List<Map<String, dynamic>>> getTransactions(String username) async {
    if (kIsWeb) {
      return await _getTransactionsWeb(username);
    } else {
      return await _getTransactionsMobile(username);
    }
  }
  
  // Mobile implementation
  Future<List<Map<String, dynamic>>> _getTransactionsMobile(String username) async {
    Database db = await database;
    return await db.query(
      'transactions',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'created_at DESC'
    );
  }
  
  // Web implementation
  Future<List<Map<String, dynamic>>> _getTransactionsWeb(String username) async {
    List<String> transactions = _prefs?.getStringList(_prefKeyTransactions) ?? [];
    List<Map<String, dynamic>> result = [];
    
    for (String jsonString in transactions) {
      Map<String, dynamic> transaction = jsonDecode(jsonString);
      if (transaction['username'] == username) {
        result.add(transaction);
      }
    }
    
    // Sort by created_at in descending order
    result.sort((a, b) {
      String dateA = a['created_at'] ?? '';
      String dateB = b['created_at'] ?? '';
      return dateB.compareTo(dateA); // Descending order
    });
    
    return result;
  }
  
  // Get pending transactions that need to be synced
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    if (kIsWeb) {
      return await _getPendingTransactionsWeb();
    } else {
      return await _getPendingTransactionsMobile();
    }
  }
  
  // Mobile implementation
  Future<List<Map<String, dynamic>>> _getPendingTransactionsMobile() async {
    Database db = await database;
    return await db.query(
      'pending_transactions',
      where: 'sync_status = ?',
      whereArgs: [0], // 0 = Not synced
      orderBy: 'created_at ASC' // Sync oldest first
    );
  }
  
  // Web implementation
  Future<List<Map<String, dynamic>>> _getPendingTransactionsWeb() async {
    List<String> pendingTransactions = _prefs?.getStringList(_prefKeyPendingTransactions) ?? [];
    List<Map<String, dynamic>> result = [];
    
    for (String jsonString in pendingTransactions) {
      Map<String, dynamic> transaction = jsonDecode(jsonString);
      if (transaction['sync_status'] == 0) {
        result.add(transaction);
      }
    }
    
    // Sort by created_at in ascending order for syncing oldest first
    result.sort((a, b) {
      String dateA = a['created_at'] ?? '';
      String dateB = b['created_at'] ?? '';
      return dateA.compareTo(dateB); // Ascending order
    });
    
    return result;
  }
  
  // Mark transaction as synced
  Future<void> markTransactionSynced(dynamic id) async {
    if (kIsWeb) {
      await _markTransactionSyncedWeb(id.toString());
    } else {
      await _markTransactionSyncedMobile(id as int);
    }
  }
  
  // Mobile implementation
  Future<void> _markTransactionSyncedMobile(int id) async {
    Database db = await database;
    await db.update(
      'pending_transactions',
      {'sync_status': 1}, // 1 = Synced
      where: 'id = ?',
      whereArgs: [id]
    );
  }
  
  // Web implementation
  Future<void> _markTransactionSyncedWeb(String id) async {
    List<String> pendingTransactions = _prefs?.getStringList(_prefKeyPendingTransactions) ?? [];
    List<String> updatedList = [];
    
    for (String jsonString in pendingTransactions) {
      Map<String, dynamic> transaction = jsonDecode(jsonString);
      if (transaction['id'] == id) {
        transaction['sync_status'] = 1; // 1 = Synced
      }
      updatedList.add(jsonEncode(transaction));
    }
    
    await _prefs?.setStringList(_prefKeyPendingTransactions, updatedList);
  }
  
  // Save user settings locally
  Future<void> saveUserSettings(String username, double monthlyIncome, bool showIncome) async {
    if (kIsWeb) {
      await _saveUserSettingsWeb(username, monthlyIncome, showIncome);
    } else {
      await _saveUserSettingsMobile(username, monthlyIncome, showIncome);
    }
  }
  
  // Mobile implementation
  Future<void> _saveUserSettingsMobile(String username, double monthlyIncome, bool showIncome) async {
    Database db = await database;
    
    // Check if user settings exist
    List<Map<String, dynamic>> existing = await db.query(
      'user_settings',
      where: 'username = ?',
      whereArgs: [username]
    );
    
    if (existing.isEmpty) {
      // Insert new settings
      await db.insert('user_settings', {
        'username': username,
        'monthly_income': monthlyIncome,
        'show_income': showIncome ? 1 : 0,
        'last_sync': DateTime.now().toIso8601String()
      });
    } else {
      // Update existing settings
      await db.update(
        'user_settings',
        {
          'monthly_income': monthlyIncome,
          'show_income': showIncome ? 1 : 0,
          'last_sync': DateTime.now().toIso8601String()
        },
        where: 'username = ?',
        whereArgs: [username]
      );
    }
  }
  
  // Web implementation
  Future<void> _saveUserSettingsWeb(String username, double monthlyIncome, bool showIncome) async {
    Map<String, dynamic> allSettings = jsonDecode(_prefs?.getString(_prefKeyUserSettings) ?? '{}');
    
    // Create/update settings for this user
    allSettings[username] = {
      'username': username,
      'monthly_income': monthlyIncome,
      'show_income': showIncome ? 1 : 0,
      'last_sync': DateTime.now().toIso8601String()
    };
    
    await _prefs?.setString(_prefKeyUserSettings, jsonEncode(allSettings));
  }
  
  // Get user settings
  Future<Map<String, dynamic>?> getUserSettings(String username) async {
    if (kIsWeb) {
      return await _getUserSettingsWeb(username);
    } else {
      return await _getUserSettingsMobile(username);
    }
  }
  
  // Mobile implementation
  Future<Map<String, dynamic>?> _getUserSettingsMobile(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'user_settings',
      where: 'username = ?',
      whereArgs: [username]
    );
    
    if (results.isEmpty) return null;
    return results.first;
  }
  
  // Web implementation
  Future<Map<String, dynamic>?> _getUserSettingsWeb(String username) async {
    Map<String, dynamic> allSettings = jsonDecode(_prefs?.getString(_prefKeyUserSettings) ?? '{}');
    
    if (allSettings.containsKey(username)) {
      return Map<String, dynamic>.from(allSettings[username]);
    }
    
    return null;
  }
  
  // Calculate total spend from local transactions
  Future<double> calculateTotalSpend(String username) async {
    if (kIsWeb) {
      return await _calculateTotalSpendWeb(username);
    } else {
      return await _calculateTotalSpendMobile(username);
    }
  }
  
  // Mobile implementation
  Future<double> _calculateTotalSpendMobile(String username) async {
    Database db = await database;
    
    // Sum the spendAmt column for the given username
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(CAST(spendAmt AS REAL)) as total FROM transactions WHERE username = ?',
      [username]
    );
    
    if (result.first['total'] == null) return 0.0;
    return result.first['total'] as double;
  }
  
  // Web implementation
  Future<double> _calculateTotalSpendWeb(String username) async {
    List<Map<String, dynamic>> transactions = await _getTransactionsWeb(username);
    
    double total = 0.0;
    for (var transaction in transactions) {
      total += double.tryParse(transaction['spendAmt'].toString()) ?? 0.0;
    }
    
    return total;
  }
  
  // Calculate remaining balance based on income and spending
  Future<double> calculateRemainingBalance(String username) async {
    double totalSpend = await calculateTotalSpend(username);
    Map<String, dynamic>? settings = await getUserSettings(username);
    
    double income = settings != null ? (settings['monthly_income'] as num).toDouble() : 15000.0;
    return income - totalSpend;
  }
  
  // Clear synced transactions to prevent the database from growing too large
  Future<void> clearSyncedTransactions() async {
    if (kIsWeb) {
      await _clearSyncedTransactionsWeb();
    } else {
      await _clearSyncedTransactionsMobile();
    }
  }
  
  // Mobile implementation
  Future<void> _clearSyncedTransactionsMobile() async {
    Database db = await database;
    await db.delete(
      'pending_transactions',
      where: 'sync_status = ?',
      whereArgs: [1] // 1 = Synced
    );
  }
  
  // Web implementation
  Future<void> _clearSyncedTransactionsWeb() async {
    List<String> pendingTransactions = _prefs?.getStringList(_prefKeyPendingTransactions) ?? [];
    List<String> updatedList = [];
    
    for (String jsonString in pendingTransactions) {
      Map<String, dynamic> transaction = jsonDecode(jsonString);
      if (transaction['sync_status'] != 1) { // Keep if not synced
        updatedList.add(jsonString);
      }
    }
    
    await _prefs?.setStringList(_prefKeyPendingTransactions, updatedList);
  }
  
  // Use a lock to ensure that sync operations don't overlap
  Future<T> withTransaction<T>(Future<T> Function(dynamic txn) action) async {
    return await _lock.synchronized(() async {
      if (kIsWeb) {
        // For web, just use null since we're using shared_preferences instead of a transaction
        return await action(null);
      } else {
        final db = await database;
        return await db.transaction((txn) => action(txn));
      }
    });
  }
} 