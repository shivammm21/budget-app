import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus {
  wifi,
  mobile,
  offline
}

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  // Controller for the stream of connectivity status
  final _connectivityStreamController = StreamController<ConnectivityStatus>.broadcast();
  
  // Subscribe to get connectivity updates
  Stream<ConnectivityStatus> get connectivityStream => _connectivityStreamController.stream;
  
  // Last known connectivity status
  ConnectivityStatus _lastStatus = ConnectivityStatus.offline;
  ConnectivityStatus get lastStatus => _lastStatus;
  
  // Initialize connectivity monitoring
  void initialize() {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
    
    // Get the initial connectivity status
    Connectivity().checkConnectivity().then((result) {
      _updateConnectionStatus(result);
    });
  }
  
  // Map ConnectivityResult to our ConnectivityStatus enum
  void _updateConnectionStatus(ConnectivityResult result) {
    ConnectivityStatus status;
    
    switch (result) {
      case ConnectivityResult.wifi:
        status = ConnectivityStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        status = ConnectivityStatus.mobile;
        break;
      case ConnectivityResult.none:
      default:
        status = ConnectivityStatus.offline;
        break;
    }
    
    // Only trigger update if status changed
    if (status != _lastStatus) {
      _lastStatus = status;
      _connectivityStreamController.add(status);
    }
  }
  
  // Check if currently online
  bool get isOnline => _lastStatus != ConnectivityStatus.offline;
  
  // Manual check connectivity (useful for initial connection attempts)
  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
    return isOnline;
  }
  
  // Dispose resources
  void dispose() {
    _connectivityStreamController.close();
  }
} 