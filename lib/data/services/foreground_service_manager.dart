import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'intent_service.dart';
import 'mqtt_service.dart';
import 'contact_service.dart';
import 'package:platform/platform.dart';

abstract class ForegroundServiceManager {
  Future<void> init();
  Future<void> requestPermissions();
  Future<bool> start({required String deviceId, required String serverUrl});
  Future<bool> stop();
  Future<bool> isRunning();
  Future<void> saveSettings({
    required String deviceId,
    required String serverUrl,
    required bool autoStart,
  });
  Future<String?> getDeviceId();
  Future<String?> getServerUrl();
  Future<bool> isAutoStartEnabled();
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MimoTaskHandler());
}

class MimoTaskHandler extends TaskHandler {
  MQTTService? _mqttService;
  String? _deviceId;
  String? _serverUrl;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Car Companion service started at $timestamp');
    
    // We need to fetch settings directly from SharedPreferences since we're in an isolate
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id') ?? 'default_device';
    _serverUrl = prefs.getString('server_url') ?? '192.168.10.7';

    // Initialize MQTT and Intent Service
    final intentService = AndroidIntentService(platform: const LocalPlatform());
    final contactService = DeviceContactService();
    _mqttService = MQTTService(
      intentService: intentService,
      contactService: contactService,
    );
    
    // Clean URL for MQTT (remove http://, https://, and paths)
    String cleanBroker = _serverUrl!;
    if (cleanBroker.startsWith('http://')) {
      cleanBroker = cleanBroker.substring(7);
    } else if (cleanBroker.startsWith('https://')) {
      cleanBroker = cleanBroker.substring(8);
    }
    if (cleanBroker.contains('/')) {
      cleanBroker = cleanBroker.split('/').first;
    }
    if (cleanBroker.contains(':')) {
      cleanBroker = cleanBroker.split(':').first;
    }

    await _mqttService!.connect(cleanBroker, _deviceId!);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    debugPrint('Car Companion service heartbeat at $timestamp');
    // Ensure MQTT is still connected
    if (_mqttService != null) {
      // Basic heartbeat logic could be added here
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('Car Companion service destroyed at $timestamp');
    _mqttService?.disconnect();
  }
}

class FlutterForegroundServiceManager implements ForegroundServiceManager {
  @override
  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'car_companion_channel',
        channelName: 'Car Companion Service',
        channelDescription: 'Maintains connection between Headunit and Robot',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // Heartbeat 30 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  Future<void> requestPermissions() async {
    // Request notification permission if needed
    final hasPermission = await FlutterForegroundTask.requestNotificationPermission();
    if (hasPermission != NotificationPermission.granted) {
      debugPrint('Notification permission denied.');
    }

    // Request SYSTEM_ALERT_WINDOW to allow starting activities from background (Android 10+)
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
    
    // Request CALL_PHONE to allow direct phone calling
    if (await Permission.phone.isDenied) {
      await Permission.phone.request();
    }

    // Request CONTACTS to allow searching contacts
    if (await Permission.contacts.isDenied) {
      await Permission.contacts.request();
    }
  }

  @override
  Future<bool> start({required String deviceId, required String serverUrl}) async {
    // Save settings and enable autoStart
    await saveSettings(deviceId: deviceId, serverUrl: serverUrl, autoStart: true);

    await requestPermissions();

    if (await FlutterForegroundTask.isRunningService) {
      // Service is already running, update it
      final result = await FlutterForegroundTask.updateService(
        notificationTitle: '✅ Car Companion Mode Active',
        notificationText: 'Device: $deviceId • Connected',
      );
      return result is ServiceRequestSuccess;
    }

    // Start service
    final result = await FlutterForegroundTask.startService(
      notificationTitle: '✅ Car Companion Mode Active',
      notificationText: 'Device: $deviceId • Connected',
      callback: startCallback,
    );

    return result is ServiceRequestSuccess;
  }

  @override
  Future<bool> stop() async {
    // Disable autoStart on manual stop
    final deviceId = await getDeviceId() ?? '';
    final serverUrl = await getServerUrl() ?? '';
    await saveSettings(deviceId: deviceId, serverUrl: serverUrl, autoStart: false);

    if (await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.stopService();
      return result is ServiceRequestSuccess;
    }
    return true;
  }

  @override
  Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  @override
  Future<void> saveSettings({
    required String deviceId,
    required String serverUrl,
    required bool autoStart,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
    await prefs.setString('server_url', serverUrl);
    await prefs.setBool('auto_start', autoStart);
  }

  @override
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
  }

  @override
  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url');
  }

  @override
  Future<bool> isAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_start') ?? false;
  }
}
