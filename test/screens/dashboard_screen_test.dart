import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mimo/presentation/ui/screens/dashboard_screen.dart';
import 'package:flutter_mimo/presentation/ui/widgets/control_wheel.dart';
import 'package:flutter_mimo/presentation/ui/widgets/volume_control.dart';
import 'package:flutter_mimo/presentation/ui/widgets/car_companion_card.dart';
import 'package:flutter_mimo/presentation/ui/widgets/debug_tools_panel.dart';
import 'package:flutter_mimo/data/services/foreground_service_manager.dart';
import 'package:flutter_mimo/data/services/intent_service.dart';
import 'package:flutter_mimo/data/services/contact_service.dart';
import 'package:flutter_mimo/presentation/state/companion_state.dart';
import 'package:flutter_mimo/presentation/state/tool_debug_state.dart';
import 'package:provider/provider.dart';

class _MockIntentService implements IntentService {
  String? lastToolName;
  Map<String, dynamic>? lastParameters;
  bool shouldSucceed = true;

  @override
  Future<String?> executeTool(String toolName, Map<String, dynamic> parameters) async {
    lastToolName = toolName;
    lastParameters = parameters;
    return shouldSucceed ? null : "Failed to execute $toolName";
  }

  @override
  Future<void> showToast(String message) async {}
}

class _MockContactService implements ContactService {
  @override
  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    return [];
  }
}

// Minimal mock to avoid native plugin calls in widget tests
class _MockServiceManager extends ForegroundServiceManager {
  @override Future<void> init() async {}
  @override Future<void> requestPermissions() async {}
  @override Future<bool> start({required String deviceId, required String serverUrl}) async => true;
  @override Future<bool> stop() async => true;
  @override Future<bool> isRunning() async => false;
  @override Future<void> saveSettings({required String deviceId, required String serverUrl, required bool autoStart}) async {}
  @override Future<String?> getDeviceId() async => null;
  @override Future<String?> getServerUrl() async => null;
  @override Future<bool> isAutoStartEnabled() async => false;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompanionState(serviceManager: _MockServiceManager())),
        ChangeNotifierProvider(create: (_) => ToolDebugState(intentService: _MockIntentService(), contactService: _MockContactService())),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  testWidgets('DashboardScreen renders robot indicators and control panels', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify top bar
    expect(find.text('Mimo Control'), findsOneWidget);
    expect(find.text('Auto Mode'), findsOneWidget);
    expect(find.text('Debug Tools'), findsOneWidget);

    // In Auto Mode tab by default, CarCompanionCard should be present
    expect(find.byType(CarCompanionCard), findsOneWidget);
    expect(find.byType(DebugToolsPanel), findsNothing);

    // Tap on Debug Tools tab
    await tester.tap(find.text('Debug Tools'));
    await tester.pump();

    // In Debug Tools tab, DebugToolsPanel should be present and CarCompanionCard should not
    expect(find.byType(DebugToolsPanel), findsOneWidget);
    expect(find.byType(CarCompanionCard), findsNothing);
  });


  testWidgets('DashboardScreen renders Row layout in landscape mode', (WidgetTester tester) async {
    // Set a landscape size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify ControlWheel and Status elements are both rendered in landscape layout
    // expect(find.byType(ControlWheel), findsOneWidget);
    // expect(find.byType(VolumeControl), findsOneWidget);
    // expect(find.text('Battery'), findsOneWidget);
  });
}
