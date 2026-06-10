import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'data/services/foreground_service_manager.dart';
import 'data/services/intent_service.dart';
import 'presentation/state/companion_state.dart';
import 'presentation/state/tool_debug_state.dart';
import 'presentation/ui/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize communication port for two-way messages
  FlutterForegroundTask.initCommunicationPort();

  final manager = FlutterForegroundServiceManager();
  await manager.init();
  
  final intentService = AndroidIntentService();

  // Auto-start on boot if enabled
  if (await manager.isAutoStartEnabled() && !(await manager.isRunning())) {
    final deviceId = await manager.getDeviceId() ?? '';
    final serverUrl = await manager.getServerUrl() ?? '';
    if (deviceId.isNotEmpty && serverUrl.isNotEmpty) {
      await manager.start(deviceId: deviceId, serverUrl: serverUrl);
    }
  }

  runApp(MyApp(
    serviceManager: manager,
    intentService: intentService,
  ));
}

class MyApp extends StatelessWidget {
  final ForegroundServiceManager serviceManager;
  final IntentService intentService;

  MyApp({
    super.key,
    ForegroundServiceManager? serviceManager,
    IntentService? intentService,
  }) : serviceManager = serviceManager ?? FlutterForegroundServiceManager(),
       intentService = intentService ?? AndroidIntentService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CompanionState(serviceManager: serviceManager),
        ),
        ChangeNotifierProvider(
          create: (_) => ToolDebugState(intentService: intentService),
        ),
      ],
      child: MaterialApp(
        title: 'Mimo Control Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1E1F22),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
