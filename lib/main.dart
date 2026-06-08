import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service_manager.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize communication port for two-way messages
  FlutterForegroundTask.initCommunicationPort();

  final manager = FlutterForegroundServiceManager();
  await manager.init();

  // Auto-start on boot if enabled
  if (await manager.isAutoStartEnabled() && !(await manager.isRunning())) {
    final deviceId = await manager.getDeviceId() ?? '';
    final serverUrl = await manager.getServerUrl() ?? '';
    if (deviceId.isNotEmpty && serverUrl.isNotEmpty) {
      await manager.start(deviceId: deviceId, serverUrl: serverUrl);
    }
  }

  runApp(MyApp(serviceManager: manager));
}

class MyApp extends StatelessWidget {
  final ForegroundServiceManager serviceManager;

  MyApp({
    super.key,
    ForegroundServiceManager? serviceManager,
  }) : serviceManager = serviceManager ?? FlutterForegroundServiceManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mimo Control Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1F22),
        useMaterial3: true,
      ),
      home: DashboardScreen(serviceManager: serviceManager),
    );
  }
}
