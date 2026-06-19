import 'package:flutter/foundation.dart';
import '../../data/services/foreground_service_manager.dart';

class CompanionState extends ChangeNotifier {
  final ForegroundServiceManager serviceManager;

  String _deviceId = '';
  String _serverUrl = '192.168.10.7';
  bool _isRunning = false;
  bool _autoStart = false;
  bool _isLoading = true;
  String _activeTab = 'Auto Mode';
  String? _error;

  CompanionState({required this.serviceManager}) {
    _init();
  }

  String get deviceId => _deviceId;
  String get serverUrl => _serverUrl;
  bool get isRunning => _isRunning;
  bool get autoStart => _autoStart;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  String? get error => _error;

  void setActiveTab(String tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final id = await serviceManager.getDeviceId();
    final url = await serviceManager.getServerUrl();
    _isRunning = await serviceManager.isRunning();
    _autoStart = await serviceManager.isAutoStartEnabled();

    // Check and request permissions on every launch
    await serviceManager.requestPermissions();

    if (id != null) _deviceId = id;
    if (url != null) _serverUrl = url;

    _isLoading = false;
    notifyListeners();
  }

  void updateCredentials({required String deviceId, required String serverUrl}) {
    _deviceId = deviceId;
    _serverUrl = serverUrl;
    // Don't notify listeners to avoid rebuilding text fields while typing if not necessary,
    // or just notify. Let's notify.
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> toggleService({required String deviceId, required String serverUrl}) async {
    _deviceId = deviceId;
    _serverUrl = serverUrl;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isRunning) {
        final success = await serviceManager.stop();
        if (success) {
          _isRunning = false;
          _autoStart = false;
        } else {
          _error = 'Failed to stop service';
        }
        return success;
      } else {
        final success = await serviceManager.start(
          deviceId: _deviceId,
          serverUrl: _serverUrl,
        );
        if (success) {
          _isRunning = true;
          _autoStart = true;
        } else {
          _error = 'Failed to start service';
        }
        return success;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
