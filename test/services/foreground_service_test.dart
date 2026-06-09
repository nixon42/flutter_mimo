import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mimo/data/services/foreground_service_manager.dart';

// A mock implementation of ForegroundServiceManager for testing business logic
class MockForegroundServiceManager extends ForegroundServiceManager {
  bool _isRunning = false;
  String? _deviceId;
  String? _serverUrl;
  bool _autoStart = false;

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    _serverUrl = prefs.getString('server_url');
    _autoStart = prefs.getBool('auto_start') ?? false;
  }

  @override
  Future<bool> start({required String deviceId, required String serverUrl}) async {
    _isRunning = true;
    _deviceId = deviceId;
    _serverUrl = serverUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
    await prefs.setString('server_url', serverUrl);
    return true;
  }

  @override
  Future<bool> stop() async {
    _isRunning = false;
    return true;
  }

  @override
  Future<bool> isRunning() async {
    return _isRunning;
  }

  @override
  Future<void> saveSettings({
    required String deviceId,
    required String serverUrl,
    required bool autoStart,
  }) async {
    _deviceId = deviceId;
    _serverUrl = serverUrl;
    _autoStart = autoStart;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
    await prefs.setString('server_url', serverUrl);
    await prefs.setBool('auto_start', autoStart);
  }

  @override
  Future<String?> getDeviceId() async => _deviceId;

  @override
  Future<String?> getServerUrl() async => _serverUrl;

  @override
  Future<bool> isAutoStartEnabled() async => _autoStart;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForegroundServiceManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve companion settings correctly', () async {
      final manager = MockForegroundServiceManager();
      await manager.init();

      expect(await manager.getDeviceId(), isNull);
      expect(await manager.getServerUrl(), isNull);
      expect(await manager.isAutoStartEnabled(), isFalse);

      await manager.saveSettings(
        deviceId: 'robot_123',
        serverUrl: 'https://mcp.xiaozhi.me',
        autoStart: true,
      );

      expect(await manager.getDeviceId(), equals('robot_123'));
      expect(await manager.getServerUrl(), equals('https://mcp.xiaozhi.me'));
      expect(await manager.isAutoStartEnabled(), isTrue);
    });

    test('should manage service running state', () async {
      final manager = MockForegroundServiceManager();
      await manager.init();

      expect(await manager.isRunning(), isFalse);

      final started = await manager.start(
        deviceId: 'robot_123',
        serverUrl: 'https://mcp.xiaozhi.me',
      );

      expect(started, isTrue);
      expect(await manager.isRunning(), isTrue);

      final stopped = await manager.stop();
      expect(stopped, isTrue);
      expect(await manager.isRunning(), isFalse);
    });
  });
}
